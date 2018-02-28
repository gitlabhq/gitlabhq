import Cookies from 'js-cookie';

export default {
  isNewRepoEnabled() {
    return Cookies.get('new_repo') === 'true';
  },
};
