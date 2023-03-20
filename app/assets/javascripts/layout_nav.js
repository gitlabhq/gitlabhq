import $ from 'jquery';
import ContextualSidebar from './contextual_sidebar';
import initFlyOutNav from './fly_out_nav';
import { setNotification } from './whats_new/utils/notification';

function hideEndFade($scrollingTabs) {
  $scrollingTabs.each(function scrollTabsLoop() {
    const $this = $(this);
    $this
      .siblings('.fade-right')
      .toggleClass('scrolling', Math.round($this.width()) < $this.prop('scrollWidth'));
  });
}

export function initScrollingTabs() {
  const $scrollingTabs = $('.scrolling-tabs').not('.is-initialized');
  $scrollingTabs.addClass('is-initialized');

  $(window)
    .on('resize.nav', () => {
      hideEndFade($scrollingTabs);
    })
    .trigger('resize.nav');

  $scrollingTabs.on('scroll', function tabsScrollEvent() {
    const $this = $(this);
    const currentPosition = $this.scrollLeft();
    const maxPosition = $this.prop('scrollWidth') - $this.outerWidth();

    $this.siblings('.fade-left').toggleClass('scrolling', currentPosition > 0);
    $this.siblings('.fade-right').toggleClass('scrolling', currentPosition < maxPosition - 1);
  });

  $scrollingTabs.each(function scrollTabsEachLoop() {
    const $this = $(this);
    const scrollingTabWidth = $this.width();
    const $active = $this.find('.active');
    const activeWidth = $active.width();

    if ($active.length) {
      const offset = $active.offset().left + activeWidth;

      if (offset > scrollingTabWidth - 30) {
        const scrollLeft = offset - scrollingTabWidth / 2 - activeWidth / 2;

        $this.scrollLeft(scrollLeft);
      }
    }
  });
}

function initDeferred() {
  initScrollingTabs();

  const appEl = document.getElementById('whats-new-app');
  if (!appEl) return;

  setNotification(appEl);

  const triggerEl = document.querySelector('.js-whats-new-trigger');
  if (!triggerEl) return;

  triggerEl.addEventListener('click', () => {
    import(/* webpackChunkName: 'whatsNewApp' */ '~/whats_new')
      .then(({ default: initWhatsNew }) => {
        initWhatsNew(appEl);
      })
      .catch(() => {});
  });
}

export default function initLayoutNav() {
  if (!gon.use_new_navigation) {
    const contextualSidebar = new ContextualSidebar();
    contextualSidebar.bindEvents();
    initFlyOutNav();
  }

  requestIdleCallback(initDeferred);
}
