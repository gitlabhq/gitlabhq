import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlToggle, GlDropdown } from '@gitlab/ui';
import IngressModsecuritySettings from '~/clusters/components/ingress_modsecurity_settings.vue';
import { APPLICATION_STATUS, INGRESS } from '~/clusters/constants';
import eventHub from '~/clusters/event_hub';

const { UPDATING } = APPLICATION_STATUS;

describe('IngressModsecuritySettings', () => {
  let wrapper;

  const defaultProps = {
    modsecurity_enabled: false,
    status: 'installable',
    installed: false,
    modsecurity_mode: 'logging',
    updateAvailable: false,
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

  const findSaveButton = () =>
    wrapper.find('[data-qa-selector="save_ingress_modsecurity_settings"]');
  const findCancelButton = () =>
    wrapper.find('[data-qa-selector="cancel_ingress_modsecurity_settings"]');
  const findModSecurityToggle = () => wrapper.find(GlToggle);
  const findModSecurityDropdown = () => wrapper.find(GlDropdown);

  describe('when ingress is installed', () => {
    beforeEach(() => {
      createComponent({ installed: true, status: 'installed' });
      jest.spyOn(eventHub, '$emit');
    });

    it('does not render save and cancel buttons', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    describe('with toggle changed by the user', () => {
      beforeEach(() => {
        findModSecurityToggle().vm.$emit('change');
        wrapper.setProps({
          ingress: {
            ...defaultProps,
            installed: true,
            status: 'installed',
            modsecurity_enabled: true,
          },
        });
      });

      it('renders save and cancel buttons', () => {
        expect(findSaveButton().exists()).toBe(true);
        expect(findCancelButton().exists()).toBe(true);
      });

      it('enables related toggle and buttons', () => {
        expect(findSaveButton().attributes().disabled).toBeUndefined();
        expect(findCancelButton().attributes().disabled).toBeUndefined();
      });

      describe('with dropdown changed by the user', () => {
        beforeEach(() => {
          findModSecurityDropdown().vm.$children[1].$emit('click');
          wrapper.setProps({
            ingress: {
              ...defaultProps,
              installed: true,
              status: 'installed',
              modsecurity_enabled: true,
              modsecurity_mode: 'blocking',
            },
          });
        });

        it('renders both save and cancel buttons', () => {
          expect(findSaveButton().exists()).toBe(true);
          expect(findCancelButton().exists()).toBe(true);
        });

        describe('and the save changes button is clicked', () => {
          beforeEach(() => {
            findSaveButton().vm.$emit('click');
          });

          it('triggers save event and pass current modsecurity value', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('updateApplication', {
              id: INGRESS,
              params: { modsecurity_enabled: true, modsecurity_mode: 'blocking' },
            });
          });
        });
      });

      describe('and the cancel button is clicked', () => {
        beforeEach(() => {
          findCancelButton().vm.$emit('click');
        });

        it('triggers reset event and hides both cancel and save changes button', () => {
          expect(eventHub.$emit).toHaveBeenCalledWith('resetIngressModSecurityChanges', INGRESS);
          expect(findSaveButton().exists()).toBe(false);
          expect(findCancelButton().exists()).toBe(false);
        });
      });

      describe('with a new version available', () => {
        beforeEach(() => {
          wrapper.setProps({
            ingress: {
              ...defaultProps,
              installed: true,
              status: 'installed',
              modsecurity_enabled: true,
              updateAvailable: true,
            },
          });
        });

        it('disables related toggle and buttons', () => {
          expect(findSaveButton().attributes().disabled).toBe('true');
          expect(findCancelButton().attributes().disabled).toBe('true');
        });
      });
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
        expect(findSaveButton().text()).toBe('Saving');
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
      expect(findModSecurityToggle().props('value')).toBe(false);
    });
  });
});
