import Cookies from 'js-cookie';

function isNewRepo() {
  return Cookies.get('new_nav') === 'true';
}

const FeatureHelper = {
  isNewRepo,
};

export default FeatureHelper;
