const CONFIDENTIAL_ISSUE_SCROLL_CLASS_NAME = 'confidential-issue-scroll';
const CONFIDENTIAL_ISSUE_WARNING_SELECTOR = '.confidential-issue-warning';

export default () => {
  /**
  * for IE11/Firefox/Edge :(
  * document.documentElement.scrollTop || document.body.scrollTop
  * if documentElement.scrollTop is 0 then we are on a non WebKit browser
  * then `body.scrollTop` will be used
  * otherwise it will return a `truthy` value :)
  **/

  const banner = document.querySelector(CONFIDENTIAL_ISSUE_WARNING_SELECTOR);
  const bannerClassList = banner.classList;

  const confidentialScroll = () => {
    const scrollTop = (
      document.documentElement.scrollTop || document.body.scrollTop
    );

    if (scrollTop > 5) {
      bannerClassList.add(CONFIDENTIAL_ISSUE_SCROLL_CLASS_NAME);
    } else {
      bannerClassList.remove(CONFIDENTIAL_ISSUE_SCROLL_CLASS_NAME);
    }
  };

  window.addEventListener('scroll', confidentialScroll);
};
