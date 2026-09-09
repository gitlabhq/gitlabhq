import { initIssuableSidebar } from '~/issuable/index';

describe('initIssuableSidebar', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  const addSidebarOptions = () => {
    const el = document.createElement('script');
    el.className = 'js-sidebar-options';
    el.type = 'application/json';
    el.textContent = JSON.stringify({ currentUser: {} });
    document.body.appendChild(el);
  };

  // The merge request AI overview renders the options without the sidebar itself.
  it('does not throw when the right sidebar is absent', () => {
    addSidebarOptions();

    expect(() => initIssuableSidebar()).not.toThrow();
  });
});
