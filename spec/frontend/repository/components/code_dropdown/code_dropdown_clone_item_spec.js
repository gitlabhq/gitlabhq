import { GlButton, GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CodeDropdownCloneItem from '~/repository/components/code_dropdown/code_dropdown_clone_item.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { COPY_SSH_CLONE_URL } from '~/repository/components/code_dropdown/constants';

describe('CodeDropdownCloneItem', () => {
  let wrapper;
  const link = 'ssh://foo.bar';
  const label = 'SSH';
  const testId = 'some-selector';
  const defaultPropsData = {
    link,
    label,
    testId,
  };

  const findCopyButton = () => wrapper.findComponent(GlButton);
  const mockToastShow = jest.fn();

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CodeDropdownCloneItem, {
      propsData,
      stubs: {
        GlFormInputGroup,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('default', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('sets form group label', () => {
      expect(wrapper.findComponent(GlFormGroup).attributes('label')).toBe(label);
    });

    it('sets form input group label', () => {
      expect(wrapper.findComponent(GlFormInputGroup).props('label')).toBe(label);
    });

    it('sets form input group link', () => {
      expect(wrapper.findComponent(GlFormInputGroup).props('value')).toBe(link);
    });

    it('sets the copy tooltip text', () => {
      expect(findCopyButton().attributes('title')).toBe('Copy URL');
    });

    it('sets the copy tooltip link', () => {
      expect(findCopyButton().attributes('data-clipboard-text')).toBe(link);
    });

    it('sets the qa selector', () => {
      expect(findCopyButton().attributes('data-testid')).toBe(testId);
    });

    it('shows toast when dropdown item is clicked', async () => {
      findCopyButton().vm.$emit('click');
      await nextTick();

      expect(mockToastShow).toHaveBeenCalledWith('Copied');
    });

    it('tracks the copy event if tracking is passed', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent({ ...defaultPropsData, tracking: { action: COPY_SSH_CLONE_URL } });

      findCopyButton().vm.$emit('click');
      await nextTick();

      expect(trackEventSpy).toHaveBeenCalledWith(COPY_SSH_CLONE_URL, {}, undefined);
    });

    it('does not track the copy event if tracking not passed', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findCopyButton().vm.$emit('click');
      await nextTick();

      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });
});
