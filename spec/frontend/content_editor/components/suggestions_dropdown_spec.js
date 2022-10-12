import { GlAvatarLabeled, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SuggestionsDropdown from '~/content_editor/components/suggestions_dropdown.vue';

describe('~/content_editor/components/suggestions_dropdown', () => {
  let wrapper;

  const buildWrapper = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(SuggestionsDropdown, {
      propsData: {
        nodeType: 'reference',
        ...propsData,
      },
    });
  };

  const exampleUser = { username: 'root', avatar_url: 'root_avatar.png', type: 'User' };
  const exampleIssue = { iid: 123, title: 'Test Issue' };
  const exampleMergeRequest = { iid: 224, title: 'Test MR' };
  const exampleMilestone = { iid: 21, title: '1.3' };
  const exampleCommand = {
    name: 'due',
    description: 'Set due date',
    params: ['<in 2 days | this Friday | December 31st>'],
  };
  const exampleEmoji = {
    c: 'people',
    e: '😃',
    d: 'smiling face with open mouth',
    u: '6.0',
    name: 'smiley',
  };

  const insertedEmojiProps = {
    name: 'smiley',
    title: 'smiling face with open mouth',
    moji: '😃',
    unicodeVersion: '6.0',
  };

  describe('on item select', () => {
    it.each`
      nodeType       | referenceType      | char   | reference              | insertedText | insertedProps
      ${'reference'} | ${'user'}          | ${'@'} | ${exampleUser}         | ${`@root`}   | ${{}}
      ${'reference'} | ${'issue'}         | ${'#'} | ${exampleIssue}        | ${`#123`}    | ${{}}
      ${'reference'} | ${'merge_request'} | ${'!'} | ${exampleMergeRequest} | ${`!224`}    | ${{}}
      ${'reference'} | ${'milestone'}     | ${'%'} | ${exampleMilestone}    | ${`%1.3`}    | ${{}}
      ${'reference'} | ${'command'}       | ${'/'} | ${exampleCommand}      | ${'/due '}   | ${{}}
      ${'emoji'}     | ${'emoji'}         | ${':'} | ${exampleEmoji}        | ${`😃`}      | ${insertedEmojiProps}
    `(
      'runs a command to insert the selected $referenceType',
      ({ char, nodeType, referenceType, reference, insertedText, insertedProps }) => {
        const commandSpy = jest.fn();

        buildWrapper({
          propsData: {
            char,
            command: commandSpy,
            nodeType,
            nodeProps: {
              referenceType,
              test: 'prop',
            },
            items: [reference],
          },
        });

        wrapper.findComponent(GlDropdownItem).vm.$emit('click');

        expect(commandSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            text: insertedText,
            test: 'prop',
            ...insertedProps,
          }),
        );
      },
    );
  });

  describe('rendering user references', () => {
    it('displays avatar labeled component', () => {
      const testUser = exampleUser;
      buildWrapper({
        propsData: {
          char: '@',
          command: jest.fn(),
          nodeType: 'reference',
          nodeProps: {
            referenceType: 'user',
          },
          items: [testUser],
        },
      });

      expect(wrapper.findComponent(GlAvatarLabeled).attributes()).toEqual(
        expect.objectContaining({
          label: testUser.username,
          shape: 'circle',
          src: testUser.avatar_url,
        }),
      );
    });

    describe.each`
      referenceType      | char   | reference              | displaysID
      ${'issue'}         | ${'#'} | ${exampleIssue}        | ${true}
      ${'merge_request'} | ${'!'} | ${exampleMergeRequest} | ${true}
      ${'milestone'}     | ${'%'} | ${exampleMilestone}    | ${false}
    `('rendering $referenceType references', ({ referenceType, char, reference, displaysID }) => {
      it(`displays ${referenceType} ID and title`, () => {
        buildWrapper({
          propsData: {
            char,
            command: jest.fn(),
            nodeType: 'reference',
            nodeProps: {
              referenceType,
            },
            items: [reference],
          },
        });

        if (displaysID) expect(wrapper.text()).toContain(`${reference.iid}`);
        else expect(wrapper.text()).not.toContain(`${reference.iid}`);
        expect(wrapper.text()).toContain(`${reference.title}`);
      });
    });

    describe('rendering a command (quick action)', () => {
      it('displays command name with a slash', () => {
        buildWrapper({
          propsData: {
            char: '/',
            command: jest.fn(),
            nodeType: 'reference',
            nodeProps: {
              referenceType: 'command',
            },
            items: [exampleCommand],
          },
        });

        expect(wrapper.text()).toContain(`${exampleCommand.name} `);
      });
    });

    describe('rendering emoji references', () => {
      it('displays emoji', () => {
        const testEmojis = [
          {
            c: 'people',
            e: '😄',
            d: 'smiling face with open mouth and smiling eyes',
            u: '6.0',
            name: 'smile',
          },
          {
            c: 'people',
            e: '😸',
            d: 'grinning cat face with smiling eyes',
            u: '6.0',
            name: 'smile_cat',
          },
          { c: 'people', e: '😃', d: 'smiling face with open mouth', u: '6.0', name: 'smiley' },
        ];

        buildWrapper({
          propsData: {
            char: ':',
            command: jest.fn(),
            nodeType: 'emoji',
            nodeProps: {},
            items: testEmojis,
          },
        });

        testEmojis.forEach((testEmoji) => {
          expect(wrapper.text()).toContain(testEmoji.e);
          expect(wrapper.text()).toContain(testEmoji.d);
          expect(wrapper.text()).toContain(testEmoji.name);
        });
      });
    });
  });
});
