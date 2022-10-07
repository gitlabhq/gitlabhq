import { nextTick } from 'vue';
import { GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';

import FormUrlApp from '~/webhooks/components/form_url_app.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FormUrlApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(FormUrlApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findAllRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findUrlMaskDisable = () => findAllRadioButtons().at(0);
  const findUrlMaskEnable = () => findAllRadioButtons().at(1);
  const findUrlMaskSection = () => wrapper.findByTestId('url-mask-section');

  describe('template', () => {
    it('renders radio buttons for URL masking', () => {
      createComponent();

      expect(findAllRadioButtons().length).toBe(2);
      expect(findUrlMaskDisable().text()).toBe(FormUrlApp.i18n.radioFullUrlText);
      expect(findUrlMaskEnable().text()).toBe(FormUrlApp.i18n.radioMaskUrlText);
    });

    it('does not render mask section', () => {
      createComponent();

      expect(findUrlMaskSection().exists()).toBe(false);
    });

    describe('on radio select', () => {
      beforeEach(async () => {
        createComponent();

        findRadioGroup().vm.$emit('input', true);
        await nextTick();
      });

      it('renders mask section', () => {
        expect(findUrlMaskSection().exists()).toBe(true);
      });
    });
  });
});
