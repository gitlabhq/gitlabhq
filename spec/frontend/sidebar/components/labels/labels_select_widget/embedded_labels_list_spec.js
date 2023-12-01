import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmbeddedLabelsList from '~/sidebar/components/labels/labels_select_widget/embedded_labels_list.vue';
import { mockRegularLabel, mockScopedLabel, mockLockedLabel } from './mock_data';

describe('EmbeddedLabelsList', () => {
  let wrapper;

  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findLabelByTitle = (title) =>
    findAllLabels()
      .filter((label) => label.props('title') === title)
      .at(0);
  const findRegularLabel = () => findLabelByTitle(mockRegularLabel.title);
  const findScopedLabel = () => findLabelByTitle(mockScopedLabel.title);
  const findLockedLabel = () => findLabelByTitle(mockLockedLabel.title);

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMountExtended(EmbeddedLabelsList, {
      slots,
      propsData: {
        selectedLabels: [mockRegularLabel, mockScopedLabel, mockLockedLabel],
        allowLabelRemove: true,
        labelsFilterBasePath: '/gitlab-org/my-project/issues',
        labelsFilterParam: 'label_name',
        ...props,
      },
      provide: {
        allowScopedLabels: true,
      },
    });
  };

  describe('when there are no labels', () => {
    beforeEach(() => {
      createComponent({
        selectedLabels: [],
      });
    });

    it('does not render any labels', () => {
      expect(findAllLabels()).toHaveLength(0);
    });
  });

  describe('when there are labels', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a list of three labels', () => {
      expect(findAllLabels()).toHaveLength(3);
    });

    it('passes correct props to the regular label', () => {
      expect(findRegularLabel().props('target')).toBe(
        '/gitlab-org/my-project/issues?label_name[]=Foo%20Label',
      );
      expect(findRegularLabel().props('scoped')).toBe(false);
    });

    it('passes correct props to the scoped label', () => {
      expect(findScopedLabel().props('target')).toBe(
        '/gitlab-org/my-project/issues?label_name[]=Foo%3A%3ABar',
      );
      expect(findScopedLabel().props('scoped')).toBe(true);
    });

    it('emits `onLabelRemove` event with the correct ID', () => {
      findRegularLabel().vm.$emit('close');
      expect(wrapper.emitted('onLabelRemove')).toStrictEqual([[mockRegularLabel.id]]);
    });

    it('does not show close button if label is locked', () => {
      createComponent({
        supportsLockOnMerge: true,
      });
      expect(findLockedLabel().props('showCloseButton')).toBe(false);
    });
  });
});
