import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';

import IssuableBody from '~/vue_shared/issuable/show/components/issuable_body.vue';

import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import IssuableEditForm from '~/vue_shared/issuable/show/components/issuable_edit_form.vue';
import IssuableTitle from '~/vue_shared/issuable/show/components/issuable_title.vue';
import TaskList from '~/task_list';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

jest.mock('~/autosave');
jest.mock('~/alert');
jest.mock('~/task_list');

const issuableBodyProps = {
  ...mockIssuableShowProps,
  issuable: mockIssuable,
};

describe('IssuableBody', () => {
  // Some assertions expect a date later than our default
  useFakeDate(2020, 11, 11);

  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(IssuableBody, {
      propsData: {
        ...issuableBodyProps,
        ...propsData,
      },
      stubs: {
        IssuableTitle,
        IssuableDescription,
        IssuableEditForm,
        TimeAgoTooltip,
      },
      slots: {
        'status-badge': 'Open',
        'edit-form-actions': `
        <button class="js-save">Save changes</button>
        <button class="js-cancel">Cancel</button>
      `,
      },
    });
  };

  const findUpdatedLink = () => wrapper.findComponent(GlLink);
  const findIssuableEditForm = () => wrapper.findComponent(IssuableEditForm);
  const findIssuableEditFormButton = (type) => findIssuableEditForm().find(`button.js-${type}`);
  const findIssuableTitle = () => wrapper.findComponent(IssuableTitle);

  beforeEach(() => {
    createComponent();
    TaskList.mockClear();
  });

  describe('computed', () => {
    describe('updatedBy', () => {
      it('returns value of `issuable.updatedBy`', () => {
        expect(findUpdatedLink().text()).toBe(mockIssuable.updatedBy.name);
        expect(findUpdatedLink().attributes('href')).toBe(mockIssuable.updatedBy.webUrl);
      });
    });
  });

  describe('watchers', () => {
    describe('editFormVisible', () => {
      it('calls initTaskList in nextTick', () => {
        createComponent({
          editFormVisible: false,
        });

        expect(TaskList).toHaveBeenCalled();
      });
    });
  });

  describe('mounted', () => {
    it('initializes TaskList instance when enabledEdit and enableTaskList props are true', () => {
      createComponent();
      expect(TaskList).toHaveBeenCalledWith({
        dataType: 'issue',
        fieldName: 'description',
        lockVersion: issuableBodyProps.taskListLockVersion,
        selector: '.js-detail-page-description',
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
      });
    });

    it('does not initialize TaskList instance when either enabledEdit or enableTaskList prop is false', () => {
      createComponent({
        ...issuableBodyProps,
        enableTaskList: false,
      });

      expect(TaskList).toHaveBeenCalledTimes(0);
    });
  });

  describe('methods', () => {
    describe('handleTaskListUpdateSuccess', () => {
      it('emits `task-list-update-success` event on component', () => {
        const updatedIssuable = {
          foo: 'bar',
        };

        wrapper.vm.handleTaskListUpdateSuccess(updatedIssuable);

        expect(wrapper.emitted('task-list-update-success')).toHaveLength(1);
        expect(wrapper.emitted('task-list-update-success')[0]).toEqual([updatedIssuable]);
      });
    });

    describe('handleTaskListUpdateFailure', () => {
      it('emits `task-list-update-failure` event on component', () => {
        wrapper.vm.handleTaskListUpdateFailure();

        expect(wrapper.emitted('task-list-update-failure')).toHaveLength(1);
      });
    });
  });

  describe('template', () => {
    it('renders issuable-title component', () => {
      expect(findIssuableTitle().exists()).toBe(true);
      expect(findIssuableTitle().props()).toMatchObject({
        issuable: issuableBodyProps.issuable,
        statusIcon: issuableBodyProps.statusIcon,
        enableEdit: issuableBodyProps.enableEdit,
        workspaceType: issuableBodyProps.workspaceType,
      });
    });

    it('renders issuable-description component', () => {
      const descriptionEl = wrapper.findComponent(IssuableDescription);

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.props('issuable')).toEqual(issuableBodyProps.issuable);
    });

    it('renders issuable edit info', () => {
      expect(wrapper.find('small').text()).toMatchInterpolatedText(
        'Edited 3 months ago by Administrator',
      );
    });

    it('renders issuable-edit-form when `editFormVisible` prop is true', () => {
      createComponent({
        editFormVisible: true,
      });

      expect(findIssuableEditForm().exists()).toBe(true);
      expect(findIssuableEditForm().props()).toMatchObject({
        issuable: issuableBodyProps.issuable,
        enableAutocomplete: issuableBodyProps.enableAutocomplete,
        descriptionPreviewPath: issuableBodyProps.descriptionPreviewPath,
        descriptionHelpPath: issuableBodyProps.descriptionHelpPath,
      });
      expect(findIssuableEditFormButton('save').exists()).toBe(true);
      expect(findIssuableEditFormButton('cancel').exists()).toBe(true);
    });

    describe('events', () => {
      it('component emits `edit-issuable` event bubbled via issuable-title', () => {
        findIssuableTitle().vm.$emit('edit-issuable');

        expect(wrapper.emitted('edit-issuable')).toHaveLength(1);
      });

      it.each(['keydown-title', 'keydown-description'])(
        'component emits `%s` event with event object and issuableMeta params via issuable-edit-form',
        (eventName) => {
          const eventObj = {
            preventDefault: jest.fn(),
            stopPropagation: jest.fn(),
          };
          const issuableMeta = {
            issuableTitle: 'foo',
            issuableDescription: 'foobar',
          };

          createComponent({
            editFormVisible: true,
          });

          findIssuableEditForm().vm.$emit(eventName, eventObj, issuableMeta);

          expect(wrapper.emitted(eventName)).toHaveLength(1);
          expect(wrapper.emitted(eventName)[0]).toMatchObject([eventObj, issuableMeta]);
        },
      );
    });
  });
});
