DROP TRIGGER IF EXISTS pgl_new_user ON users;
DROP TRIGGER IF EXISTS pgl_new_project ON projects;
DROP TRIGGER IF EXISTS pgl_update_project ON projects;

CREATE OR REPLACE FUNCTION pgl_create_user_team_rs() RETURNS trigger
LANGUAGE plpgsql
AS $$
	DECLARE m_user_team_id integer;
	DECLARE m_projects_id integer;
	BEGIN
		m_user_team_id := 0;
		SELECT "id" INTO m_user_team_id
		  	FROM "user_teams" p
		WHERE p.name = 'pgl_reporters'
		LIMIT 1;

		FOR m_projects_id IN SELECT project_id FROM user_team_project_relationships WHERE user_team_id = m_user_team_id LOOP
			INSERT INTO users_projects (user_id, project_id, created_at, updated_at, project_access) 
			VALUES (NEW.id, m_projects_id, now(), now(), 20);
		END LOOP;

		INSERT INTO user_team_user_relationships (user_id, user_team_id, permission, created_at, updated_at) VALUES (NEW.id, m_user_team_id, 20, now(), now());
		RETURN new;
	END;
$$;
CREATE TRIGGER pgl_new_user AFTER INSERT ON users FOR EACH ROW EXECUTE PROCEDURE pgl_create_user_team_rs();

CREATE OR REPLACE FUNCTION pgl_create_project_team_rs() RETURNS trigger
LANGUAGE plpgsql
AS $$
	DECLARE m_user_team_id integer;
	DECLARE m_users_id integer;
	BEGIN
		IF NEW.public = 't' THEN	
			m_user_team_id := 0;
			SELECT "id" INTO m_user_team_id
			  	FROM "user_teams" p
			WHERE p.name = 'pgl_reporters'
			LIMIT 1;

			FOR m_users_id IN SELECT user_id FROM user_team_user_relationships WHERE user_team_id = m_user_team_id  LOOP
				IF m_users_id <> NEW.creator_id THEN
					INSERT INTO users_projects (user_id, project_id, created_at, updated_at, project_access) 
					VALUES (m_users_id, NEW.id, now(), now(), 20);
				END IF;
			END LOOP;

			INSERT INTO user_team_project_relationships (project_id, user_team_id, greatest_access, created_at, updated_at) VALUES (NEW.id, m_user_team_id, 20, now(), now());			
		END IF;
		RETURN new;
	END;
$$;
CREATE TRIGGER pgl_new_project AFTER INSERT ON projects FOR EACH ROW EXECUTE PROCEDURE pgl_create_project_team_rs();

CREATE OR REPLACE FUNCTION pgl_update_project_team_rs() RETURNS trigger
LANGUAGE plpgsql
AS $$
	DECLARE 
		m_user_team_id integer;
		m_users_id integer;
		temprec RECORD;
		tmpint  INTEGER := 0;
	BEGIN
		IF NEW.public <> OLD.public THEN
			m_user_team_id := 0;
			SELECT "id" INTO m_user_team_id
			  	FROM "user_teams" p
			WHERE p.name = 'pgl_reporters'
			LIMIT 1;

			IF NEW.public = 't' THEN	
				FOR m_users_id IN SELECT user_id FROM user_team_user_relationships WHERE user_team_id = m_user_team_id  LOOP
					IF m_users_id <> OLD.creator_id THEN
						SELECT user_id FROM users_projects WHERE user_id = m_users_id AND project_id = OLD.id INTO temprec;
						GET DIAGNOSTICS tmpint = ROW_COUNT;
						IF tmpint = 0 THEN
							INSERT INTO users_projects (user_id, project_id, created_at, updated_at, project_access) 
							VALUES (m_users_id, OLD.id, now(), now(), 20);
						END IF;
					END IF;
				END LOOP;

				INSERT INTO user_team_project_relationships (project_id, user_team_id, greatest_access, created_at, updated_at) VALUES (OLD.id, m_user_team_id, 20, now(), now());			

			ELSE
				FOR m_users_id IN SELECT user_id FROM user_team_user_relationships WHERE user_team_id = m_user_team_id LOOP
					SELECT project_access INTO tmpint FROM users_projects WHERE user_id = m_users_id AND project_id = OLD.id LIMIT 1;
					-- If project permission is reporter (20), or lower
					IF tmpint < 21 THEN
						DELETE FROM users_projects WHERE user_id = m_users_id AND project_id = OLD.id;
					END IF;
				END LOOP;
				DELETE FROM user_team_project_relationships WHERE user_team_id = m_user_team_id AND project_id = OLD.id;
			END IF;
		END IF;
		RETURN new;
	END;
$$;
CREATE TRIGGER pgl_update_project AFTER UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE pgl_update_project_team_rs();