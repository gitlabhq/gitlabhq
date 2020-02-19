import { shallowMount } from '@vue/test-utils';
import IngressModsecuritySettings from '~/clusters/components/ingress_modsecurity_settings.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { APPLICATION_STATUS, INGRESS } from '~/clusters/constants';
import { GlAlert } from '@gitlab/ui';
import eventHub from '~/clusters/event_hub';

const { UPDATING } = APPLICATION_STATUS;

describe('IngressModsecuritySettings', () => {
  let wrapper;

  const defaultProps = {
    modsecurity_enabled: false,
    status: 'installable',
    installed: false,
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMount(IngressModsecuritySettings, {
      propsData: {
        ingress: {
          ...defaultProps,
          ...props,
        },
      },
    });
  };

  const findSaveButton = () => wrapper.find(LoadingButton);
  const findModSecurityCheckbox = () => wrapper.find('input').element;

  describe('when ingress is installed', () => {
    beforeEach(() => {
      createComponent({ installed: true });
      jest.spyOn(eventHub, '$emit');
    });

    it('renders save button', () => {
      expect(findSaveButton().exists()).toBe(true);
      expect(findModSecurityCheckbox().checked).toBe(false);
    });

    describe('and the save changes button is clicked', () => {
      beforeEach(() => {
        findSaveButton().vm.$emit('click');
      });

      it('triggers save event and pass current modsecurity value', () =>
        wrapper.vm.$nextTick().then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('updateApplication', {
            id: INGRESS,
            params: { modsecurity_enabled: false },
          });
        }));
    });

    it('triggers set event to be propagated with the current modsecurity value', () => {
      wrapper.setData({ modSecurityEnabled: true });
      return wrapper.vm.$nextTick().then(() => {
        expect(eventHub.$emit).toHaveBeenCalledWith('setIngressModSecurityEnabled', {
          id: INGRESS,
          modSecurityEnabled: true,
        });
      });
    });

    describe(`when ingress status is ${UPDATING}`, () => {
      beforeEach(() => {
        createComponent({ installed: true, status: UPDATING });
      });

      it('renders loading spinner in save button', () => {
        expect(findSaveButton().props('loading')).toBe(true);
      });

      it('renders disabled save button', () => {
        expect(findSaveButton().props('disabled')).toBe(true);
      });

      it('renders save button with "Saving" label', () => {
        expect(findSaveButton().props('label')).toBe('Saving');
      });
    });

    describe('when ingress fails to update', () => {
      beforeEach(() => {
        createComponent({ updateFailed: true });
      });

      it('displays a error message', () => {
        expect(wrapper.find(GlAlert).exists()).toBe(true);
      });
    });
  });

  describe('when ingress is not installed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the save button', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findModSecurityCheckbox().checked).toBe(false);
    });
  });
});
