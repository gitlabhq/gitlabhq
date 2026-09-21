/**
 * Sets the current user on `window.gon`, which `shared_test_setup.js` resets to a
 * logged-out gon before every test. Field names mirror `getCurrentUser` in
 * `~/lib/utils/common_utils`, which reads them back.
 */
export const setCurrentUser = ({
  id = 1,
  username = 'root',
  name = 'Administrator',
  avatarUrl = '/avatar.png',
} = {}) => {
  window.gon.current_user_id = id;
  window.gon.current_username = username;
  window.gon.current_user_fullname = name;
  window.gon.current_user_avatar_url = avatarUrl;
};
