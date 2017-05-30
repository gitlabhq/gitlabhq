export default () => {
  const body = document.body;
  const banner = document.querySelector('.confidential-issue-warning');
  const bannerClassList = banner.classList;

  const confidentialScroll = () => {
    if (body.scrollTop > 60) {
      bannerClassList.add('confidential-issue-scroll');
    } else {
      bannerClassList.remove('confidential-issue-scroll');
    }
  };

  window.addEventListener('scroll', confidentialScroll);
};
