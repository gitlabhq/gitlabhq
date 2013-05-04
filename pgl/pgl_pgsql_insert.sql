INSERT INTO users (email, encrypted_password, name, username, projects_limit, can_create_team, can_create_group, sign_in_count, created_at, updated_at, admin ) 
VALUES ('guest@local.host', '$2a$10$ivc.WwouK4tKT3ZtV8kiD.oVZRzJLV0df7K4nJRV73hhf9a92JeJ.', 'guest', 'guest', 0, 'f', 'f', 0, now(), now(), 'f');

INSERT INTO user_teams (name, path, owner_id, created_at, updated_at, description)
VALUES ('pgl_reporters', 'pgl_reporters', (SELECT id FROM users WHERE username = 'root'), now(), now(), 'Default new users team (reporter permission)');
