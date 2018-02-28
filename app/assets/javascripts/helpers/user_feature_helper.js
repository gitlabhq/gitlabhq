import Cookies from 'js-cookie';

function isNewRepo() {
  return Cookies.get('new_repo') === 'true';
}

const UserFeatureHelper = {
  isNewRepo,
};

export default UserFeatureHelper;
