import { GlButton, GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import TriggerBlock from '~/ci/job_details/components/sidebar/trigger_block.vue';

describe('Trigger block', () => {
  let wrapper;

  const findRevealButton = () => wrapper.findComponent(GlButton);
  const findVariableTable = () => wrapper.findComponent(GlTableLite);
  const findShortToken = () => wrapper.find('[data-testid="trigger-short-token"]');
  const findVariableValue = (index) =>
    wrapper.findAll('[data-testid="trigger-build-value"]').at(index);
  const findVariableKey = (index) => wrapper.findAll('[data-testid="trigger-build-key"]').at(index);

  const createComponent = (props) => {
    wrapper = mount(TriggerBlock, {
      propsData: {
        ...props,
      },
    });
  };

  describe('with short token and no variables', () => {
    it('renders short token', () => {
      createComponent({
        trigger: {
          short_token: '0a666b2',
          variables: [],
        },
      });

      expect(findShortToken().text()).toContain('0a666b2');
    });
  });

  describe('without variables or short token', () => {
    beforeEach(() => {
      createComponent({ trigger: { variables: [] } });
    });

    it('does not render short token', () => {
      expect(findShortToken().exists()).toBe(false);
    });

    it('does not render variables', () => {
      expect(findRevealButton().exists()).toBe(false);
      expect(findVariableTable().exists()).toBe(false);
    });
  });

  describe('with variables', () => {
    describe('hide/reveal variables', () => {
      it('should toggle variables on click', async () => {
        const hiddenValue = '••••••';
        const gcsVar = { key: 'UPLOAD_TO_GCS', value: 'false', public: false };
        const s3Var = { key: 'UPLOAD_TO_S3', value: 'true', public: false };

        createComponent({
          trigger: {
            variables: [gcsVar, s3Var],
          },
        });

        expect(findRevealButton().text()).toBe('Reveal values');

        expect(findVariableValue(0).text()).toBe(hiddenValue);
        expect(findVariableValue(1).text()).toBe(hiddenValue);

        expect(findVariableKey(0).text()).toBe(gcsVar.key);
        expect(findVariableKey(1).text()).toBe(s3Var.key);

        await findRevealButton().trigger('click');

        expect(findRevealButton().text()).toBe('Hide values');

        expect(findVariableValue(0).text()).toBe(gcsVar.value);
        expect(findVariableValue(1).text()).toBe(s3Var.value);
      });
    });
  });
});
