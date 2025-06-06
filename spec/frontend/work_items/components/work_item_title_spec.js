import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';

describe('Work Item title', () => {
  let wrapper;
  const mockTitle = 'Work Item _title_ :smile:';
  const mockTitleHtml =
    'Work Item <em>title</em> <gl-emoji title="grinning face with smiling eyes" data-name="smile" data-unicode-version="6.0">😄</gl-emoji>';
  const mockTitleHtmlResult =
    '<h1 data-testid="work-item-title" class="gl-heading-1 !gl-m-0 gl-w-full gl-wrap-anywhere"><span>Work Item <em>title</em> <gl-emoji title="grinning face with smiling eyes" data-name="smile" data-unicode-version="6.0">😄</gl-emoji></span></h1>';
  const mockTitleText = 'Work Item title 😄';

  const createComponent = ({ isEditing = false, isModal = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemTitle, {
      propsData: {
        title: mockTitle,
        titleHtml: mockTitleHtml,
        isEditing,
        isModal,
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('work-item-title');
  const findEditableTitleForm = () => wrapper.findComponent(GlFormGroup);
  const findEditableTitleInput = () => wrapper.findComponent(GlFormInput);

  describe('Default mode', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe(mockTitleText);
      expect(findTitle().html()).toBe(mockTitleHtmlResult);
    });

    it.each`
      expectedTag | isModal
      ${'H1'}     | ${undefined}
      ${'H1'}     | ${false}
      ${'H2'}     | ${true}
    `('renders the title as an $expectedTag if isModal is $isModal', ({ expectedTag, isModal }) => {
      createComponent({ isModal });
      expect(findTitle().element.tagName).toBe(expectedTag);
    });

    it('does not render edit mode', () => {
      expect(findEditableTitleForm().exists()).toBe(false);
    });
  });

  describe('Edit mode', () => {
    beforeEach(() => {
      createComponent({ isEditing: true });
    });

    it('does not render read only title', () => {
      expect(findTitle().exists()).toBe(false);
    });

    it('renders the editable title with label', () => {
      expect(findEditableTitleForm().exists()).toBe(true);
      expect(findEditableTitleForm().attributes('label')).toBe(WorkItemTitle.i18n.titleLabel);
    });

    it('emits `updateDraft` event on change of the input', () => {
      findEditableTitleInput().vm.$emit('input', 'updated title');

      expect(wrapper.emitted('updateDraft')).toEqual([['updated title']]);
    });
  });
});
