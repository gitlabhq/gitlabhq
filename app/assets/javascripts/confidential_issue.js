export default () => {
  /**
  * for IE11/Firefox/Edge :(
  * document.documentElement.scrollTop || document.body.scrollTop
  * if documentElement.scrollTop is 0 then we are on a non WebKit browser
  * then `body.scrollTop` will be used
  * otherwise it will return a `truthy` value :)
  **/

  const banner = document.querySelector('.confidential-issue-warning');
  const bannerClassList = banner.classList;

  const confidentialScroll = () => {
    if ((document.documentElement.scrollTop || document.body.scrollTop) > 5) {
      bannerClassList.add('confidential-issue-scroll');
    } else {
      bannerClassList.remove('confidential-issue-scroll');
    }
  };

  window.addEventListener('scroll', confidentialScroll);
};
