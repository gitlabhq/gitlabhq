-- NOT SUPPORTED YET

INSERT INTO users (email, encrypted_password, name, username, projects_limit, can_create_team, can_create_group, sign_in_count, created_at, updated_at, admin )
VALUES ('guest@local.host', '$2a$10$ivc.WwouK4tKT3ZtV8kiD.oVZRzJLV0df7K4nJRV73hhf9a92JeJ.', 'guest', 'guest', 0, 'f', 'f', 0, now(), now(), 'f');

INSERT INTO user_teams (name, path, owner_id, created_at, updated_at, description)
VALUES ('pgl_reporters', 'pgl_reporters', (SELECT id FROM users WHERE username = 'root'), now(), now(), 'Default new users team (reporter permission)');

 -- MySQL wants something like that
DROP TRIGGER IF EXISTS pgl_new_user;
delimiter //

CREATE TRIGGER pgl_new_user
AFTER INSERT ON users FOR EACH ROW
BEGIN
    DECLARE m_user_team_id integer;    
    SELECT id INTO m_user_team_id FROM user_teams WHERE name = "pgl_reporters";

    DECLARE m_projects_id integer;
    DECLARE cur CURSOR FOR SELECT project_id FROM user_team_project_relationships WHERE user_team_id = m_user_team_id;
    
    DECLARE done INT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- SET @m_user_team_id := (SELECT id FROM user_teams WHERE name = "pgl_reporters");

    OPEN cur;
        ins_loop: LOOP
            FETCH cur INTO m_projects_id;
            IF done THEN
                LEAVE ins_loop;
            END IF;

            INSERT INTO users_projects (user_id, project_id, created_at, updated_at, project_access)
            VALUES (NEW.id, m_projects_id, now(), now(), 20);
        END LOOP;
    CLOSE cur;

    INSERT INTO user_team_user_relationships (user_id, user_team_id, permission, created_at, updated_at) VALUES (NEW.id, m_user_team_id, 20, now(), now());
END//
DELIMITER ;

DROP TRIGGER IF EXISTS pgl_new_user;
delimiter //

CREATE TRIGGER pgl_new_project
AFTER INSERT ON users FOR EACH ROW
BEGIN
    DECLARE m_user_team_id integer;    
    SELECT id INTO m_user_team_id FROM user_teams WHERE name = "pgl_reporters";

    DECLARE m_users_id integer;
    DECLARE cur CURSOR FOR SELECT user_id FROM user_team_user_relationships WHERE user_team_id = m_user_team_id;
    
    DECLARE done INT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
        ins_loop: LOOP
            FETCH cur INTO m_users_id;
            IF done THEN
                LEAVE ins_loop;
            END IF;

            INSERT INTO users_projects (user_id, project_id, created_at, updated_at, project_access)
            VALUES (m_users_id, NEW.id, now(), now(), 20);
        END LOOP;
    CLOSE cur;

    INSERT INTO user_team_project_relationships (project_id, user_team_id, greatest_access, created_at, updated_at) VALUES (NEW.id, m_user_team_id, 20, now(), now());            
END//
DELIMITER ;
