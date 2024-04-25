import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LabelActions from '~/labels/components/label_actions.vue';
import eventHub, { EVENT_OPEN_DELETE_LABEL_MODAL } from '~/labels/event_hub';

describe('LabelActions', () => {
  let wrapper;

  const defaultPropsData = {
    labelId: '1',
    labelName: 'Label1',
    editPath: '/admin/labels/1/edit',
    destroyPath: '/admin/labels/1',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(LabelActions, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const getDropdownItemsProp = () => findDropdown().props('items');
  const findDeleteAction = () => wrapper.findByTestId('delete-label-action');

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

    expect(getDropdownItemsProp()).toMatchObject([
      {
        text: 'Edit',
        href: defaultPropsData.editPath,
      },
      {
        text: 'Delete',
        extraAttrs: {
          class: 'gl-text-red-500!',
        },
        action: expect.any(Function),
      },
    ]);
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
