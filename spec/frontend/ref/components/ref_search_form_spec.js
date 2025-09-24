import { GlFormInputGroup, GlCollapsibleListbox, GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefSearchForm from '~/ref/components/ref_search_form.vue';
import * as urlUtility from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('RefSearchForm', () => {
  let wrapper;
  const networkPath = '/namespace/project/-/network/main';

  const createComponent = (props = {}) => {
    return shallowMountExtended(RefSearchForm, {
      propsData: {
        networkPath,
        ...props,
      },
      stubs: {
        GlFormInputGroup,
      },
    });
  };

  const findForm = () => wrapper.find('form');
  const findInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    jest.spyOn(urlUtility, 'visitUrl').mockImplementation();

    wrapper = createComponent();
  });

  describe('component rendering', () => {
    it('renders the form with all required components', () => {
      expect(findForm().exists()).toBe(true);
      expect(findInputGroup().exists()).toBe(true);
      expect(findCollapsibleListbox().exists()).toBe(true);
      expect(findInput().exists()).toBe(true);
      expect(findButton().exists()).toBe(true);
    });
  });

  describe('data initialization', () => {
    it('sets selectedOptionIndex to 0 by default', () => {
      expect(findCollapsibleListbox().props('selected')).toBe(0);
    });

    it('sets selectedOptionIndex to 1 when filter_ref is in URL', () => {
      setWindowLocation('?filter_ref=1');

      // Re-create component to pick up the new URL params
      wrapper = createComponent();

      expect(findCollapsibleListbox().props('selected')).toBe(1);
    });

    it('sets searchSha input to given value when extended_sha1 is in URL', () => {
      setWindowLocation('?extended_sha1=123');

      // Re-create component to pick up the new URL params
      wrapper = createComponent();

      expect(findInput().props('value')).toBe('123');
    });
  });

  describe('submitForm', () => {
    it('sets the selected revision parameters correctly', async () => {
      const submitFormSpy = jest.spyOn(wrapper.vm, 'submitForm');

      await findInput().vm.$emit('input', 'abc123');

      await findForm().trigger('submit');

      expect(submitFormSpy).toHaveBeenCalled();
      expect(urlUtility.visitUrl).toHaveBeenLastCalledWith(
        'http://test.host/namespace/project/-/network/main?extended_sha1=abc123',
      );
    });

    it('sets filter_ref parameter when Display up to revision is selected', async () => {
      const submitFormSpy = jest.spyOn(wrapper.vm, 'submitForm');

      await findInput().vm.$emit('input', 'test123');
      await findCollapsibleListbox().vm.$emit('select', 1);

      await findForm().trigger('submit');

      expect(submitFormSpy).toHaveBeenCalled();
      expect(urlUtility.visitUrl).toHaveBeenLastCalledWith(
        'http://test.host/namespace/project/-/network/main?extended_sha1=test123&filter_ref=1',
      );
    });

    it('does not set filter_ref parameter when Display full history is selected', async () => {
      const submitFormSpy = jest.spyOn(wrapper.vm, 'submitForm');

      await findInput().vm.$emit('input', 'test456');
      await findCollapsibleListbox().vm.$emit('select', 0);

      await findForm().trigger('submit');

      expect(submitFormSpy).toHaveBeenCalled();
      expect(urlUtility.visitUrl).toHaveBeenLastCalledWith(
        'http://test.host/namespace/project/-/network/main?extended_sha1=test456',
      );
    });
  });
});
