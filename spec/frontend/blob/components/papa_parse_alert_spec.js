import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import PapaParseAlert from '~/blob/components/papa_parse_alert.vue';

describe('app/assets/javascripts/vue_shared/components/papa_parse_alert.vue', () => {
  let wrapper;

  const createComponent = ({ errorMessages } = {}) => {
    wrapper = shallowMount(PapaParseAlert, {
      propsData: {
        papaParseErrors: errorMessages,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  it('should render alert with correct props', async () => {
    createComponent({ errorMessages: [{ code: 'MissingQuotes' }] });
    await nextTick();

    expect(findAlert().props()).toMatchObject({
      variant: 'danger',
    });
    expect(findAlert().text()).toContain(
      'Failed to render the CSV file for the following reasons:',
    );
    expect(findAlert().text()).toContain('Quoted field unterminated');
  });

  it('should render original message if no translation available', async () => {
    createComponent({
      errorMessages: [{ code: 'NotDefined', message: 'Error code is undefined' }],
    });
    await nextTick();

    expect(findAlert().text()).toContain('Error code is undefined');
  });
});
