import { mountExtended } from 'helpers/vue_test_utils_helper';
import PanelActions from '~/vue_shared/components/panel_actions.vue';

describe('PanelActions', () => {
  let wrapper;

  const findCloseButton = () => wrapper.findByRole('button', { name: 'Close panel' });
  const findMaximizeLink = () => wrapper.findByRole('link', { name: 'Open in full page' });
  const findPortalTarget = () => wrapper.find('.js-panel-actions-portal-target');

  const createComponent = (options = {}) => {
    wrapper = mountExtended(PanelActions, options);
  };

  describe('by default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the close button', () => {
      expect(findCloseButton().exists()).toBe(true);
    });

    it('does not render the maximize link', () => {
      expect(findMaximizeLink().exists()).toBe(false);
    });

    it('emits close when the close button is clicked', async () => {
      await findCloseButton().trigger('click');
      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('always renders the portal target element', () => {
      expect(findPortalTarget().exists()).toBe(true);
    });
  });

  it('renders default slot content', () => {
    const CustomAction = { template: '<button>Custom action</button>' };
    createComponent({ slots: { default: CustomAction } });
    expect(wrapper.findComponent(CustomAction).exists()).toBe(true);
  });

  describe('when maximizeUrl is provided', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          maximizeUrl:
            // Use hash for link to avoid jsdom navigation error
            '#some-link',
        },
      });
    });

    it('renders the maximize button', () => {
      expect(findMaximizeLink().exists()).toBe(true);
    });

    it('maximize button links to the maximizeUrl', () => {
      expect(findMaximizeLink().attributes('href')).toBe('#some-link');
    });

    it('emits maximize with the click event when the maximize button is clicked', async () => {
      const link = await findMaximizeLink();
      await link.trigger('click');

      expect(wrapper.emitted('maximize')).toHaveLength(1);

      const payload = wrapper.emitted('maximize')[0][0];
      expect(payload).toBeInstanceOf(MouseEvent);
      expect(payload.target).toBe(link.element);
    });
  });
});
