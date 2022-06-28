export const initDetailsButton = () => {
  document.querySelector('.commit-info').addEventListener('click', function expand(e) {
    e.preventDefault();
    this.querySelector('.js-details-content').classList.remove('hide');
    this.querySelector('.js-details-expand').classList.add('gl-display-none');
  });
};
