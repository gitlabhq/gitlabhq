import Vue from 'vue';
import CustomizeHomepageBanner from './components/customize_homepage_banner.vue';

export default () => {
  const el = document.querySelector('.js-customize-homepage-banner');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    provide: { ...el.dataset },
    render: (createElement) => createElement(CustomizeHomepageBanner),
  });
};
