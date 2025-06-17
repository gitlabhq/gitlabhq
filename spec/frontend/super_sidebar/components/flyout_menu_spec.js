import { autoUpdate } from '@floating-ui/dom';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FlyoutMenu, { FLYOUT_PADDING } from '~/super_sidebar/components/flyout_menu.vue';
import { setHTMLFixture } from 'helpers/fixtures';

jest.mock('@floating-ui/dom');

describe('FlyoutMenu', () => {
  const targetId = 'section-1';
  let wrapper;
  let autoUpdateCleanup;

  const createComponent = () => {
    wrapper = mountExtended(FlyoutMenu, {
      attachTo: document.body,
      propsData: {
        targetId,
        items: [{ id: 1, title: 'item 1', link: 'https://example.com' }],
      },
    });
  };

  beforeEach(() => {
    autoUpdateCleanup = autoUpdate.mockReturnValue(jest.fn());
    setHTMLFixture(`
      <div id="${targetId}"></div>
      <div id="${targetId}-flyout"></div>
      <div id="super-sidebar"></div>
    `);
  });

  it('renders the component', () => {
    createComponent();
    expect(wrapper.exists()).toBe(true);
  });

  it('applies the correct padding', () => {
    createComponent();
    expect(wrapper.element.style.padding).toContain(`${FLYOUT_PADDING}px`);
    expect(wrapper.element.style.paddingLeft).toContain(`${FLYOUT_PADDING * 2}px`);
  });

  it('cleans up', () => {
    createComponent();
    wrapper.destroy();
    expect(autoUpdateCleanup).toHaveBeenCalled();
  });
});
