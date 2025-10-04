import { debounce } from 'lodash';

const PANEL_SELECTOR = '.panel-content-inner';
const CSS_VARIABLE = '--panel-content-inner-height';

const measurePanel = () => {
  const panel = document.querySelector(PANEL_SELECTOR);
  return panel?.getBoundingClientRect().height ?? '';
};

const setCSSVar = debounce(() => {
  const height = measurePanel();
  if (height) {
    document.documentElement.style.setProperty(CSS_VARIABLE, `${height}px`);
  } else {
    document.documentElement.style.setProperty(CSS_VARIABLE, null);
  }
}, 200);

export default () => {
  setCSSVar();

  window.addEventListener('resize', setCSSVar);

  return () => {
    window.removeEventListener('resize', setCSSVar);
  };
};
