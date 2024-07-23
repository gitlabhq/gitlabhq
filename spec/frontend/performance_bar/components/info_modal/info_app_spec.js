import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InfoApp from '~/performance_bar/components/info_modal/info_app.vue';

let wrapper;

const defaultCurrentRequest = {
  id: '123',
  url: '/root',
  fullUrl: '/root?query="value"',
  method: 'GET',
  details: { host: { hostname: 'my-pc', canary: null } },
};

const createComponent = ({ props = {} } = {}) => {
  wrapper = shallowMountExtended(InfoApp, {
    propsData: {
      currentRequest: defaultCurrentRequest,
      ...props,
    },
    stubs: {
      GlEmoji: { template: '<div/>' },
    },
  });
};

const findCanaryIcon = () => wrapper.findByTestId('canary-emoji');
const findGlModal = () => wrapper.findComponent(GlModal);
const findHostIcon = () => wrapper.findByTestId('host-emoji');
const findInfoButton = () => wrapper.findComponent(GlButton);

describe('InfoApp component', () => {
  describe('information button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders button and passes correct props', () => {
      expect(findInfoButton().exists()).toBe(true);
      expect(findInfoButton().props()).toMatchObject({
        disabled: false,
        icon: 'information-o',
        variant: 'link',
      });
    });

    it('does not show the modal', () => {
      expect(findGlModal().props().visible).toBe(false);
    });

    describe('when clicked', () => {
      beforeEach(() => {
        findInfoButton().vm.$emit('click');
      });

      it('opens the modal', () => {
        expect(findGlModal().props().visible).toBe(true);
      });
    });
  });

  describe('when there is a host', () => {
    it('shows the host information', () => {
      createComponent();

      expect(findHostIcon().exists()).toBe(true);
      expect(wrapper.text()).toContain('my-pc');
    });

    describe('and the request was made from canary', () => {
      beforeEach(() => {
        createComponent({
          props: {
            currentRequest: {
              ...defaultCurrentRequest,
              details: {
                host: {
                  canary: true,
                },
              },
            },
          },
        });
      });

      it('shows the canary icon and text', () => {
        expect(findCanaryIcon().exists()).toBe(true);
        expect(wrapper.text()).toContain('Request made from Canary');
      });
    });

    describe('and the request was not made from canary', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not show canary information', () => {
        expect(findCanaryIcon().exists()).toBe(false);
        expect(wrapper.text()).not.toContain('Request made from Canary');
      });
    });
  });

  describe('when there are no host', () => {
    beforeEach(() => {
      createComponent({ props: { currentRequest: {} } });
    });

    it('renders text to explain no host was found', () => {
      expect(findHostIcon().exists()).toBe(true);
      expect(wrapper.text()).toContain('There is no host');
    });
  });
});
