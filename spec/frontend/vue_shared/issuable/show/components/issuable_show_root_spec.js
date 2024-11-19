import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import IssuableBody from '~/vue_shared/issuable/show/components/issuable_body.vue';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import IssuableShowRoot from '~/vue_shared/issuable/show/components/issuable_show_root.vue';

import IssuableSidebar from '~/vue_shared/issuable/sidebar/components/issuable_sidebar_root.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

const createComponent = (propsData = mockIssuableShowProps) =>
  shallowMount(IssuableShowRoot, {
    propsData,
    stubs: {
      IssuableHeader,
      IssuableBody,
      IssuableSidebar,
    },
    slots: {
      'status-badge': 'Open',
      'header-actions': `
        <button class="js-close">Close issuable</button>
        <a class="js-new" href="/gitlab-org/gitlab-shell/-/issues/new">New issuable</a>
      `,
      'edit-form-actions': `
        <button class="js-save">Save changes</button>
        <button class="js-cancel">Cancel</button>
      `,
      'right-sidebar-items': `
        <div class="js-todo">
          To Do <button class="js-add-todo">Add a to-do item</button>
        </div>
      `,
    },
  });

describe('IssuableShowRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('template', () => {
    const {
      statusIcon,
      statusIconClass,
      enableEdit,
      enableAutocomplete,
      editFormVisible,
      descriptionPreviewPath,
      descriptionHelpPath,
      taskCompletionStatus,
      workspaceType,
    } = mockIssuableShowProps;
    const { state, blocked, confidential, createdAt, author } = mockIssuable;

    it('renders component container element with class `issuable-show-container`', () => {
      expect(wrapper.classes()).toContain('issuable-show-container');
    });

    it('renders issuable-header component', () => {
      const issuableHeader = wrapper.findComponent(IssuableHeader);

      expect(issuableHeader.exists()).toBe(true);
      expect(issuableHeader.props()).toMatchObject({
        issuableState: state,
        statusIcon,
        statusIconClass,
        blocked,
        confidential,
        createdAt,
        author,
        taskCompletionStatus,
      });
      expect(issuableHeader.findComponent(GlBadge).text()).toBe('Open');
      expect(issuableHeader.find('.detail-page-header-actions button.js-close').exists()).toBe(
        true,
      );
      expect(issuableHeader.find('.detail-page-header-actions a.js-new').exists()).toBe(true);
    });

    it('renders issuable-body component', () => {
      const issuableBody = wrapper.findComponent(IssuableBody);

      expect(issuableBody.exists()).toBe(true);
      expect(issuableBody.props()).toMatchObject({
        issuable: mockIssuable,
        statusIcon,
        enableEdit,
        enableAutocomplete,
        editFormVisible,
        descriptionPreviewPath,
        descriptionHelpPath,
        workspaceType,
      });
    });

    it('renders issuable-sidebar component', () => {
      const issuableSidebar = wrapper.findComponent(IssuableSidebar);

      expect(issuableSidebar.exists()).toBe(true);
    });

    describe('events', () => {
      it('component emits `edit-issuable` event bubbled via issuable-body', () => {
        const issuableBody = wrapper.findComponent(IssuableBody);

        issuableBody.vm.$emit('edit-issuable');

        expect(wrapper.emitted('edit-issuable')).toHaveLength(1);
      });

      it('component emits `task-list-update-success` event bubbled via issuable-body', () => {
        const issuableBody = wrapper.findComponent(IssuableBody);
        const eventParam = {
          foo: 'bar',
        };

        issuableBody.vm.$emit('task-list-update-success', eventParam);

        expect(wrapper.emitted('task-list-update-success')).toHaveLength(1);
        expect(wrapper.emitted('task-list-update-success')[0]).toEqual([eventParam]);
      });

      it('component emits `task-list-update-failure` event bubbled via issuable-body', () => {
        const issuableBody = wrapper.findComponent(IssuableBody);

        issuableBody.vm.$emit('task-list-update-failure');

        expect(wrapper.emitted('task-list-update-failure')).toHaveLength(1);
      });

      it.each(['keydown-title', 'keydown-description'])(
        'component emits `%s` event with event object and issuableMeta params via issuable-body',
        (eventName) => {
          const eventObj = {
            preventDefault: jest.fn(),
            stopPropagation: jest.fn(),
          };
          const issuableMeta = {
            issuableTitle: 'foo',
            issuableDescription: 'foobar',
          };

          const issuableBody = wrapper.findComponent(IssuableBody);

          issuableBody.vm.$emit(eventName, eventObj, issuableMeta);

          expect(wrapper.emitted()).toHaveProperty(eventName);
          expect(wrapper.emitted(eventName)[0]).toMatchObject([eventObj, issuableMeta]);
        },
      );
    });
  });
});
