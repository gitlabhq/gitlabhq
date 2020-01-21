import { shallowMount } from '@vue/test-utils';
import KnativeDomainEditor from '~/clusters/components/knative_domain_editor.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { APPLICATION_STATUS } from '~/clusters/constants';

const { UPDATING } = APPLICATION_STATUS;

describe('KnativeDomainEditor', () => {
  let wrapper;
  let knative;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(KnativeDomainEditor, {
      propsData: { ...props },
    });
  };

  beforeEach(() => {
    knative = {
      title: 'Knative',
      hostname: 'example.com',
      installed: true,
    };
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('knative has an assigned IP address', () => {
    beforeEach(() => {
      knative.externalIp = '1.1.1.1';
      createComponent({ knative });
    });

    it('renders ip address with a clipboard button', () => {
      expect(wrapper.find('.js-knative-endpoint').exists()).toBe(true);
      expect(wrapper.find('.js-knative-endpoint').element.value).toEqual(knative.externalIp);
    });

    it('displays ip address clipboard button', () => {
      expect(wrapper.find('.js-knative-endpoint-clipboard-btn').attributes('text')).toEqual(
        knative.externalIp,
      );
    });

    it('renders domain & allows editing', () => {
      const domainNameInput = wrapper.find('.js-knative-domainname');

      expect(domainNameInput.element.value).toEqual(knative.hostname);
      expect(domainNameInput.attributes('readonly')).toBeFalsy();
    });

    it('renders an update/save Knative domain button', () => {
      expect(wrapper.find('.js-knative-save-domain-button').exists()).toBe(true);
    });
  });

  describe('knative without ip address', () => {
    beforeEach(() => {
      knative.externalIp = null;
      createComponent({ knative });
    });

    it('renders an input text with a loading icon', () => {
      expect(wrapper.find('.js-knative-ip-loading-icon').exists()).toBe(true);
    });

    it('renders message indicating there is not IP address assigned', () => {
      expect(wrapper.find('.js-no-knative-endpoint-message').exists()).toBe(true);
    });
  });

  describe('clicking save changes button', () => {
    beforeEach(() => {
      createComponent({ knative });
    });

    it('triggers save event and pass current knative hostname', () => {
      wrapper.find(LoadingButton).vm.$emit('click');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('save')[0]).toEqual([knative.hostname]);
      });
    });
  });

  describe('when knative domain name was saved successfully', () => {
    beforeEach(() => {
      createComponent({ knative });
    });

    it('displays toast indicating a successful update', () => {
      wrapper.vm.$toast = { show: jest.fn() };
      wrapper.setProps({ knative: Object.assign({ updateSuccessful: true }, knative) });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
          'Knative domain name was updated successfully.',
        );
      });
    });
  });

  describe('when knative domain name input changes', () => {
    it('emits "set" event with updated domain name', () => {
      createComponent({ knative });

      const newHostname = 'newhostname.com';

      wrapper.setData({ knativeHostname: newHostname });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('set')[0]).toEqual([newHostname]);
      });
    });
  });

  describe('when updating knative domain name failed', () => {
    beforeEach(() => {
      createComponent({ knative });
    });

    it('displays an error banner indicating the operation failure', () => {
      wrapper.setProps({ knative: { updateFailed: true, ...knative } });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.js-cluster-knative-domain-name-failure-message').exists()).toBe(true);
      });
    });
  });

  describe(`when knative status is ${UPDATING}`, () => {
    beforeEach(() => {
      createComponent({ knative: { status: UPDATING, ...knative } });
    });

    it('renders loading spinner in save button', () => {
      expect(wrapper.find(LoadingButton).props('loading')).toBe(true);
    });

    it('renders disabled save button', () => {
      expect(wrapper.find(LoadingButton).props('disabled')).toBe(true);
    });

    it('renders save button with "Saving" label', () => {
      expect(wrapper.find(LoadingButton).props('label')).toBe('Saving');
    });
  });
});
