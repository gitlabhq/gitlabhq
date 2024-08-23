import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LabelActions from '~/labels/components/label_actions.vue';
import eventHub, {
  EVENT_OPEN_DELETE_LABEL_MODAL,
  EVENT_OPEN_PROMOTE_LABEL_MODAL,
} from '~/labels/event_hub';

describe('LabelActions', () => {
  let wrapper;

  const defaultPropsData = {
    labelId: '1',
    labelName: 'Label1',
    labelColor: '#ffffff',
    labelTextColor: '#000000',
    subjectName: 'My Test Project',
    editPath: '/admin/labels/1/edit',
    destroyPath: '/admin/labels/1',
    promotePath: '/my-test-group/my-test-project/-/labels/1/promote',
    groupName: 'My Test Group',
  };

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(LabelActions, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const findDeleteAction = () => wrapper.findByTestId('delete-label-action');
  const findPromoteAction = () => wrapper.findByTestId('promote-label-action');

  it('renders `GlDisclosureDropdown` with expected props', () => {
    createComponent();

    expect(findDropdown().props()).toMatchObject({
      icon: 'ellipsis_v',
      noCaret: true,
      placement: 'bottom-start',
      category: 'tertiary',
    });
  });

  it('renders dropdown actions', () => {
    createComponent();

    const items = findDropdown().props('items');
    expect(items).toHaveLength(3);

    const [editItem, promoteItem, deleteItem] = items;

    expect(editItem).toMatchObject({
      text: 'Edit',
      href: defaultPropsData.editPath,
    });

    expect(promoteItem).toMatchObject({
      text: 'Promote to group label',
      action: expect.any(Function),
    });

    expect(deleteItem).toMatchObject({
      text: 'Delete',
      action: expect.any(Function),
      extraAttrs: {
        class: '!gl-text-red-500',
      },
    });
  });

  describe('Promote', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('emits open promote label modal', () => {
      createComponent();

      findPromoteAction().trigger('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_PROMOTE_LABEL_MODAL,
        expect.objectContaining({
          labelTitle: defaultPropsData.labelName,
          labelColor: defaultPropsData.labelColor,
          labelTextColor: defaultPropsData.labelTextColor,
          url: defaultPropsData.promotePath,
          groupName: defaultPropsData.groupName,
        }),
      );
    });

    it('does not render promote action', () => {
      createComponent({ promotePath: '' });

      const items = findDropdown().props('items');
      expect(items).toHaveLength(2);
      expect(items.map((item) => item.text)).not.toContain('Promote to group label');
    });
  });

  describe('DELETE', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('emits open delete label modal', () => {
      createComponent();

      findDeleteAction().trigger('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_DELETE_LABEL_MODAL,
        expect.objectContaining({
          labelId: defaultPropsData.labelId,
          labelName: defaultPropsData.labelName,
          destroyPath: defaultPropsData.destroyPath,
        }),
      );
    });
  });
});
