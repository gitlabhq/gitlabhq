import { shallowMount } from '@vue/test-utils';
import FluentdOutputSettings from '~/clusters/components/fluentd_output_settings.vue';
import { APPLICATION_STATUS, FLUENTD } from '~/clusters/constants';
import { GlAlert, GlDropdown } from '@gitlab/ui';
import eventHub from '~/clusters/event_hub';

const { UPDATING } = APPLICATION_STATUS;

describe('FluentdOutputSettings', () => {
  let wrapper;

  const defaultProps = {
    status: 'installable',
    installed: false,
    updateAvailable: false,
    protocol: 'tcp',
    host: '127.0.0.1',
    port: 514,
    isEditingSettings: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FluentdOutputSettings, {
      propsData: {
        fluentd: {
          ...defaultProps,
          ...props,
        },
      },
    });
  };

  const findSaveButton = () => wrapper.find({ ref: 'saveBtn' });
  const findCancelButton = () => wrapper.find({ ref: 'cancelBtn' });
  const findProtocolDropdown = () => wrapper.find(GlDropdown);

  describe('when fluentd is installed', () => {
    beforeEach(() => {
      createComponent({ installed: true, status: 'installed' });
      jest.spyOn(eventHub, '$emit');
    });

    it('does not render save and cancel buttons', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    describe('with protocol dropdown changed by the user', () => {
      beforeEach(() => {
        findProtocolDropdown().vm.$children[1].$emit('click');
        wrapper.setProps({
          fluentd: {
            ...defaultProps,
            installed: true,
            status: 'installed',
            protocol: 'udp',
            isEditingSettings: true,
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

      it('triggers set event to be propagated with the current value', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith('setFluentdSettings', {
          id: FLUENTD,
          host: '127.0.0.1',
          port: 514,
          protocol: 'UDP',
        });
      });

      describe('and the save changes button is clicked', () => {
        beforeEach(() => {
          findSaveButton().vm.$emit('click');
        });

        it('triggers save event and pass current values', () => {
          expect(eventHub.$emit).toHaveBeenCalledWith('updateApplication', {
            id: FLUENTD,
            params: {
              host: '127.0.0.1',
              port: 514,
              protocol: 'udp',
            },
          });
        });
      });

      describe('and the cancel button is clicked', () => {
        beforeEach(() => {
          findCancelButton().vm.$emit('click');
          wrapper.setProps({
            fluentd: {
              ...defaultProps,
              installed: true,
              status: 'installed',
              protocol: 'udp',
              isEditingSettings: false,
            },
          });
        });

        it('triggers reset event and hides both cancel and save changes button', () => {
          expect(findSaveButton().exists()).toBe(false);
          expect(findCancelButton().exists()).toBe(false);
        });
      });
    });

    describe(`when fluentd status is ${UPDATING}`, () => {
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

    describe('when fluentd fails to update', () => {
      beforeEach(() => {
        createComponent({ updateFailed: true });
      });

      it('displays a error message', () => {
        expect(wrapper.contains(GlAlert)).toBe(true);
      });
    });
  });

  describe('when fluentd is not installed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the save button', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });
  });
});
