import { GlAlert, GlDropdown, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FluentdOutputSettings from '~/clusters/components/fluentd_output_settings.vue';
import { APPLICATION_STATUS, FLUENTD } from '~/clusters/constants';
import eventHub from '~/clusters/event_hub';

const { UPDATING } = APPLICATION_STATUS;

describe('FluentdOutputSettings', () => {
  let wrapper;

  const defaultSettings = {
    protocol: 'tcp',
    host: '127.0.0.1',
    port: 514,
    wafLogEnabled: true,
    ciliumLogEnabled: false,
  };
  const defaultProps = {
    status: 'installable',
    updateFailed: false,
    ...defaultSettings,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(FluentdOutputSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };
  const updateComponentPropsFromEvent = () => {
    const { isEditingSettings, ...props } = eventHub.$emit.mock.calls[0][1];
    wrapper.setProps(props);
  };
  const findSaveButton = () => wrapper.find({ ref: 'saveBtn' });
  const findCancelButton = () => wrapper.find({ ref: 'cancelBtn' });
  const findProtocolDropdown = () => wrapper.find(GlDropdown);
  const findCheckbox = (name) =>
    wrapper.findAll(GlFormCheckbox).wrappers.find((x) => x.text() === name);
  const findHost = () => wrapper.find('#fluentd-host');
  const findPort = () => wrapper.find('#fluentd-port');
  const changeCheckbox = (checkbox) => {
    const currentValue = checkbox.attributes('checked')?.toString() === 'true';
    checkbox.vm.$emit('input', !currentValue);
  };
  const changeInput = ({ element }, val) => {
    element.value = val;
    element.dispatchEvent(new Event('input'));
  };
  const changePort = (val) => changeInput(findPort(), val);
  const changeHost = (val) => changeInput(findHost(), val);
  const changeProtocol = (idx) => findProtocolDropdown().vm.$children[idx].$emit('click');
  const toApplicationSettings = ({ wafLogEnabled, ciliumLogEnabled, ...settings }) => ({
    ...settings,
    waf_log_enabled: wafLogEnabled,
    cilium_log_enabled: ciliumLogEnabled,
  });

  describe('when fluentd is installed', () => {
    beforeEach(() => {
      createComponent({ status: 'installed' });
      jest.spyOn(eventHub, '$emit');
    });

    it('does not render save and cancel buttons', () => {
      expect(findSaveButton().exists()).toBe(false);
      expect(findCancelButton().exists()).toBe(false);
    });

    describe.each`
      desc                                     | changeFn                                                                      | key                   | value
      ${'when protocol dropdown is triggered'} | ${() => changeProtocol(1)}                                                    | ${'protocol'}         | ${'udp'}
      ${'when host is changed'}                | ${() => changeHost('test-host')}                                              | ${'host'}             | ${'test-host'}
      ${'when port is changed'}                | ${() => changePort(123)}                                                      | ${'port'}             | ${123}
      ${'when wafLogEnabled changes'}          | ${() => changeCheckbox(findCheckbox('Send Web Application Firewall Logs'))}   | ${'wafLogEnabled'}    | ${!defaultSettings.wafLogEnabled}
      ${'when ciliumLogEnabled changes'}       | ${() => changeCheckbox(findCheckbox('Send Container Network Policies Logs'))} | ${'ciliumLogEnabled'} | ${!defaultSettings.ciliumLogEnabled}
    `('$desc', ({ changeFn, key, value }) => {
      beforeEach(() => {
        changeFn();
      });

      it('triggers set event to be propagated with the current value', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith('setFluentdSettings', {
          [key]: value,
          isEditingSettings: true,
        });
      });

      describe('when value is updated from store', () => {
        beforeEach(() => {
          updateComponentPropsFromEvent();
        });

        it('enables save and cancel buttons', () => {
          expect(findSaveButton().exists()).toBe(true);
          expect(findSaveButton().attributes().disabled).toBeUndefined();
          expect(findCancelButton().exists()).toBe(true);
          expect(findCancelButton().attributes().disabled).toBeUndefined();
        });

        describe('and the save changes button is clicked', () => {
          beforeEach(() => {
            eventHub.$emit.mockClear();
            findSaveButton().vm.$emit('click');
          });

          it('triggers save event and pass current values', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('updateApplication', {
              id: FLUENTD,
              params: toApplicationSettings({
                ...defaultSettings,
                [key]: value,
              }),
            });
          });
        });

        describe('and the cancel button is clicked', () => {
          beforeEach(() => {
            eventHub.$emit.mockClear();
            findCancelButton().vm.$emit('click');
          });

          it('triggers reset event', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('setFluentdSettings', {
              ...defaultSettings,
              isEditingSettings: false,
            });
          });

          describe('when value is updated from store', () => {
            beforeEach(() => {
              updateComponentPropsFromEvent();
            });

            it('does not render save and cancel buttons', () => {
              expect(findSaveButton().exists()).toBe(false);
              expect(findCancelButton().exists()).toBe(false);
            });
          });
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
        expect(wrapper.find(GlAlert).exists()).toBe(true);
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
