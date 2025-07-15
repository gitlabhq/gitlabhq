import { shallowMount } from '@vue/test-utils';
import { GlLink, GlAvatar, GlAvatarLink } from '@gitlab/ui';
import TodoItemTitle from '~/todos/components/todo_item_title.vue';
import TodoItemTitleHiddenBySaml from '~/todos/components/todo_item_title_hidden_by_saml.vue';

import TodoItemBody from '~/todos/components/todo_item_body.vue';
import {
  TODO_ACTION_TYPE_ADDED_APPROVER,
  TODO_ACTION_TYPE_APPROVAL_REQUIRED,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
  TODO_ACTION_TYPE_MARKED,
  TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
  TODO_ACTION_TYPE_MENTIONED,
  TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
  TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_SUBMITTED,
  TODO_ACTION_TYPE_UNMERGEABLE,
  TODO_ACTION_TYPE_SSH_KEY_EXPIRED,
  TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON,
  TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED,
  TODO_ACTION_TYPE_DUO_ENTERPRISE_ACCESS_GRANTED,
  TODO_ACTION_TYPE_DUO_CORE_ACCESS_GRANTED,
} from '~/todos/constants';
import { SAML_HIDDEN_TODO } from '../mock_data';

describe('TodoItemBody', () => {
  let wrapper;

  const createComponent = (todoExtras = {}, otherProps = {}) => {
    wrapper = shallowMount(TodoItemBody, {
      propsData: {
        todo: {
          author: {
            id: '2',
            name: 'John Doe',
            webUrl: '/john',
            avatarUrl: '/avatar.png',
          },
          action: TODO_ACTION_TYPE_ASSIGNED,
          targetEntity: {
            name: 'Foo',
          },
          ...todoExtras,
        },
        isHiddenBySaml: false,
        ...otherProps,
      },
      provide: {
        currentUserId: '1',
      },
    });
  };

  it('renders TodoItemTitle component for normal todos', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemTitle).exists()).toBe(true);
  });

  it('renders TodoItemTitleHiddenBySaml component for hidden todos', () => {
    createComponent({}, { isHiddenBySaml: true });
    expect(wrapper.findComponent(TodoItemTitleHiddenBySaml).exists()).toBe(true);
  });

  it('renders author avatar', () => {
    createComponent();
    expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(true);
    expect(wrapper.findComponent(GlAvatar).props('src')).toBe('/avatar.png');
  });

  it('renders author name with link', () => {
    createComponent();
    const authorLink = wrapper.findComponent(GlLink);
    expect(authorLink.text()).toBe('John Doe');
    expect(authorLink.attributes('href')).toBe('/john');
  });

  describe('correct text for actionName', () => {
    it.each`
      actionName                                        | text                                          | showsAuthor
      ${TODO_ACTION_TYPE_ADDED_APPROVER}                | ${'created a merge request you can approve.'} | ${true}
      ${TODO_ACTION_TYPE_APPROVAL_REQUIRED}             | ${'created a merge request you can approve.'} | ${true}
      ${TODO_ACTION_TYPE_ASSIGNED}                      | ${'assigned you.'}                            | ${true}
      ${TODO_ACTION_TYPE_BUILD_FAILED}                  | ${'The pipeline failed.'}                     | ${false}
      ${TODO_ACTION_TYPE_DIRECTLY_ADDRESSED}            | ${'mentioned you.'}                           | ${true}
      ${TODO_ACTION_TYPE_MARKED}                        | ${'added a to-do item'}                       | ${true}
      ${TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED}       | ${'has requested access to group Foo'}        | ${true}
      ${TODO_ACTION_TYPE_MENTIONED}                     | ${'mentioned you.'}                           | ${true}
      ${TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED}           | ${'Removed from Merge Train.'}                | ${false}
      ${TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED}         | ${'requested an OKR update for Foo'}          | ${true}
      ${TODO_ACTION_TYPE_REVIEW_REQUESTED}              | ${'requested a review.'}                      | ${true}
      ${TODO_ACTION_TYPE_REVIEW_SUBMITTED}              | ${'reviewed your merge request.'}             | ${true}
      ${TODO_ACTION_TYPE_UNMERGEABLE}                   | ${'Could not merge.'}                         | ${false}
      ${TODO_ACTION_TYPE_SSH_KEY_EXPIRED}               | ${'Your SSH key has expired.'}                | ${false}
      ${TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON}         | ${'Your SSH key is expiring soon.'}           | ${false}
      ${TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED}        | ${'some duo body text'}                       | ${false}
      ${TODO_ACTION_TYPE_DUO_ENTERPRISE_ACCESS_GRANTED} | ${'some duo body text'}                       | ${false}
      ${TODO_ACTION_TYPE_DUO_CORE_ACCESS_GRANTED}       | ${'some duo body text'}                       | ${false}
    `('renders "$text" for the "$actionName" action', ({ actionName, text, showsAuthor }) => {
      createComponent({ action: actionName, memberAccessType: 'group', body: text });
      expect(wrapper.text()).toContain(text);
      expect(wrapper.text().includes('John Doe')).toBe(showsAuthor);
    });
  });

  describe('when todo is hidden by SAML', () => {
    it('hides the author as "Someone" with a link to the todo', () => {
      createComponent({}, { todo: SAML_HIDDEN_TODO, isHiddenBySaml: true });
      const authorLink = wrapper.findComponent(GlLink);
      expect(authorLink.text()).toBe('Someone');
      expect(authorLink.attributes('href')).toBe(SAML_HIDDEN_TODO.targetUrl);

      expect(wrapper.findComponent(GlAvatarLink).attributes('href')).toBe(
        SAML_HIDDEN_TODO.targetUrl,
      );
      expect(wrapper.findComponent(GlAvatar).props('src')).toBe(gon.default_avatar_url);
    });
  });

  it.each([
    TODO_ACTION_TYPE_DUO_ENTERPRISE_ACCESS_GRANTED,
    TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED,
    TODO_ACTION_TYPE_DUO_CORE_ACCESS_GRANTED,
  ])('when todo action is `%s`, and user is author, avatar is not shown', (action) => {
    createComponent({ action, author: { id: '1' } });
    expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(false);
  });

  it.each([
    TODO_ACTION_TYPE_DUO_ENTERPRISE_ACCESS_GRANTED,
    TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED,
    TODO_ACTION_TYPE_DUO_CORE_ACCESS_GRANTED,
  ])('when todo action is `%s` and user is not author, avatar is shown', (action) => {
    createComponent({ action });
    expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(true);
  });

  describe('when todo has a note', () => {
    it('renders note text', () => {
      createComponent({ note: { bodyFirstLineHtml: '<p>This is a note</p>' } });
      expect(wrapper.html()).toContain('<span>This is a note</span>');
    });

    it('does not render actionName', () => {
      createComponent({ note: { bodyFirstLineHtml: '<p>This is a note</p>' } });
      expect(wrapper.vm.actionName).toBeNull();
    });
  });

  describe('when current user is the author', () => {
    it('renders "You" instead of author name', () => {
      createComponent({ author: { id: '1' } });
      expect(wrapper.text()).toContain('You');
    });

    it('renders correct text for self-assigned action', () => {
      createComponent({
        author: { id: '1' },
        action: TODO_ACTION_TYPE_ASSIGNED,
      });
      expect(wrapper.text()).toContain('assigned to yourself.');
    });
  });
});
