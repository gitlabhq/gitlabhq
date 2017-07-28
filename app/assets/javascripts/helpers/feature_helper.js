import Cookies from 'js-cookie';

function isNewRepo() {
  return Cookies.get('new_repo') === 'true';
}

const FeatureHelper = {
  isNewRepo,
};

export default FeatureHelper;
