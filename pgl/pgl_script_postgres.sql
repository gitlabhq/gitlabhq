INSERT INTO users (email, encrypted_password, name, username, projects_limit, can_create_team, can_create_group, sign_in_count, created_at, updated_at, admin ) 
VALUES ('guest@local.host', '$2a$10$ivc.WwouK4tKT3ZtV8kiD.oVZRzJLV0df7K4nJRV73hhf9a92JeJ.', 'guest', 'guest', 0, 'f', 'f', 0, now(), now(), 'f');

INSERT INTO user_teams (name, path, owner_id, created_at, updated_at, description)
VALUES ('pgl_reporters', 'pgl_reporters', (SELECT id FROM users WHERE username = 'root'), now(), now(), 'Default new users team (reporter permission)');

CREATE FUNCTION pgl_create_user_team_rs() RETURNS trigger
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

CREATE FUNCTION pgl_create_project_team_rs() RETURNS trigger
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
				INSERT INTO users_projects (user_id, project_id, created_at, updated_at, project_access) 
				VALUES (m_users_id, NEW.id, now(), now(), 20);
			END LOOP;

			INSERT INTO user_team_project_relationships (project_id, user_team_id, greatest_access, created_at, updated_at) VALUES (NEW.id, m_user_team_id, 20, now(), now());			
		END IF;
		RETURN new;
	END;
$$;
CREATE TRIGGER pgl_new_project AFTER INSERT ON projects FOR EACH ROW EXECUTE PROCEDURE pgl_create_project_team_rs();
