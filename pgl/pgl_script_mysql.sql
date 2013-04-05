-- NOT SUPPORTED YET

/* -- MySQL wants something like that
DROP TRIGGER IF EXISTS pgl_new_user;
delimiter //

CREATE TRIGGER pgl_new_user 
AFTER INSERT ON users FOR EACH ROW
BEGIN
    DECLARE m_user_team_id integer;
	SELECT @m_user_team_id:=id FROM user_teams WHERE name = "pgl_reporters";
	DECLARE m_projects_id integer;
	DECLARE cur CURSOR FOR SELECT project_id FROM user_team_project_relationships WHERE user_team_id = m_user_team_id;
	

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
DELIMITER ;*/