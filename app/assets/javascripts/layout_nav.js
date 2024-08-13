import $ from 'jquery';

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

  const el = $scrollingTabs.get(0);
  const parentElement = el?.parentNode;
  if (el && parentElement) {
    parentElement.querySelector('button.fade-left')?.addEventListener('click', () => {
      el.scrollBy({ left: -200, behavior: 'smooth' });
    });
    parentElement.querySelector('button.fade-right')?.addEventListener('click', () => {
      el.scrollBy({ left: 200, behavior: 'smooth' });
    });
  }

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

function initInviteMembers() {
  const modalEl = document.querySelector('.js-invite-members-modal');
  if (modalEl) {
    import(
      /* webpackChunkName: 'initInviteMembersModal' */ '~/invite_members/init_invite_members_modal'
    )
      .then(({ default: initInviteMembersModal }) => {
        initInviteMembersModal();
      })
      .catch(() => {});
  }

  const inviteTriggers = document.querySelectorAll('.js-invite-members-trigger');
  if (!inviteTriggers) return;

  import(
    /* webpackChunkName: 'initInviteMembersTrigger' */ '~/invite_members/init_invite_members_trigger'
  )
    .then(({ default: initInviteMembersTrigger }) => {
      initInviteMembersTrigger();
    })
    .catch(() => {});
}

function initDeferred() {
  initScrollingTabs();
  initInviteMembers();
}

export default function initLayoutNav() {
  requestIdleCallback(initDeferred);
}
