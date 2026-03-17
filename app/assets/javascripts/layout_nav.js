function hideEndFade(scrollingTabs) {
  scrollingTabs.forEach((el) => {
    el.parentNode
      ?.querySelector('.fade-right')
      ?.classList.toggle('scrolling', Math.round(el.offsetWidth) < el.scrollWidth);
  });
}

export function initScrollingTabs() {
  const scrollingTabs = [...document.querySelectorAll('.scrolling-tabs:not(.is-initialized)')];
  scrollingTabs.forEach((el) => el.classList.add('is-initialized'));

  const el = scrollingTabs[0];
  const parentElement = el?.parentNode;
  if (el && parentElement) {
    parentElement.querySelector('button.fade-left')?.addEventListener('click', () => {
      el.scrollBy({ left: -200, behavior: 'smooth' });
    });
    parentElement.querySelector('button.fade-right')?.addEventListener('click', () => {
      el.scrollBy({ left: 200, behavior: 'smooth' });
    });
  }

  const resizeObserver = new ResizeObserver(() => {
    hideEndFade(scrollingTabs);
  });
  scrollingTabs.forEach((scrollTab) => resizeObserver.observe(scrollTab));
  hideEndFade(scrollingTabs);

  scrollingTabs.forEach((scrollTab) => {
    scrollTab.addEventListener('scroll', () => {
      const currentPosition = scrollTab.scrollLeft;
      const maxPosition = scrollTab.scrollWidth - scrollTab.offsetWidth;

      scrollTab.parentNode
        ?.querySelector('.fade-left')
        ?.classList.toggle('scrolling', currentPosition > 0);
      scrollTab.parentNode
        ?.querySelector('.fade-right')
        ?.classList.toggle('scrolling', currentPosition < maxPosition - 1);
    });
  });

  scrollingTabs.forEach((scrollTab) => {
    const scrollingTabWidth = scrollTab.offsetWidth;
    const activeEl = scrollTab.querySelector('.active');

    if (activeEl) {
      const activeWidth = activeEl.offsetWidth;
      const offset =
        activeEl.getBoundingClientRect().left -
        scrollTab.getBoundingClientRect().left +
        activeWidth;

      if (offset > scrollingTabWidth - 30) {
        const scrollLeftValue = offset - scrollingTabWidth / 2 - activeWidth / 2;

        scrollTab.scrollTo({ left: scrollLeftValue });
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
