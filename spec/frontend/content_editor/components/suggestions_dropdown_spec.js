import { GlDropdownItem, GlAvatarLabeled, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SuggestionsDropdown from '~/content_editor/components/suggestions_dropdown.vue';

describe('~/content_editor/components/suggestions_dropdown', () => {
  let wrapper;

  const buildWrapper = ({ propsData } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SuggestionsDropdown, {
        propsData: {
          nodeType: 'reference',
          command: jest.fn(),
          ...propsData,
        },
      }),
    );
  };

  const exampleUser = { username: 'root', avatar_url: 'root_avatar.png', type: 'User' };
  const exampleIssue = { iid: 123, title: 'Test Issue' };
  const exampleMergeRequest = { iid: 224, title: 'Test MR' };
  const exampleMilestone1 = { iid: 21, title: '13' };
  const exampleMilestone2 = { iid: 24, title: 'Milestone with spaces' };

  const exampleCommand = {
    name: 'due',
    description: 'Set due date',
    params: ['<in 2 days | this Friday | December 31st>'],
  };
  const exampleEpic = {
    iid: 8884,
    title: '❓ Remote Development | Solution validation',
    reference: 'gitlab-org&8884',
  };
  const exampleLabel1 = {
    title: 'Create',
    color: '#E44D2A',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  };
  const exampleLabel2 = {
    title: 'Weekly Team Announcement',
    color: '#E44D2A',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  };
  const exampleLabel3 = {
    title: 'devops::create',
    color: '#E44D2A',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  };
  const exampleVulnerability = {
    id: 60850147,
    title: 'System procs network activity',
  };
  const exampleSnippet = {
    id: 2420859,
    title: 'Project creation QueryRecorder logs',
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

  it.each`
    loading  | description
    ${false} | ${'does not show a loading indicator'}
    ${true}  | ${'shows a loading indicator'}
  `('$description if loading=$loading', ({ loading }) => {
    buildWrapper({
      propsData: {
        loading,
        char: '@',
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'member',
        },
        items: [exampleUser],
      },
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(loading);
  });

  describe('on item select', () => {
    it.each`
      nodeType       | referenceType      | char                 | reference               | insertedText                  | insertedProps
      ${'reference'} | ${'user'}          | ${'@'}               | ${exampleUser}          | ${`@root`}                    | ${{}}
      ${'reference'} | ${'issue'}         | ${'#'}               | ${exampleIssue}         | ${`#123`}                     | ${{}}
      ${'reference'} | ${'merge_request'} | ${'!'}               | ${exampleMergeRequest}  | ${`!224`}                     | ${{}}
      ${'reference'} | ${'milestone'}     | ${'%'}               | ${exampleMilestone1}    | ${`%13`}                      | ${{}}
      ${'reference'} | ${'milestone'}     | ${'%'}               | ${exampleMilestone2}    | ${`%Milestone with spaces`}   | ${{ originalText: '%"Milestone with spaces"' }}
      ${'reference'} | ${'command'}       | ${'/'}               | ${exampleCommand}       | ${'/due'}                     | ${{}}
      ${'reference'} | ${'epic'}          | ${'&'}               | ${exampleEpic}          | ${`gitlab-org&8884`}          | ${{}}
      ${'reference'} | ${'label'}         | ${'~'}               | ${exampleLabel1}        | ${`Create`}                   | ${{}}
      ${'reference'} | ${'label'}         | ${'~'}               | ${exampleLabel2}        | ${`Weekly Team Announcement`} | ${{ originalText: '~"Weekly Team Announcement"' }}
      ${'reference'} | ${'label'}         | ${'~'}               | ${exampleLabel3}        | ${`devops::create`}           | ${{ originalText: '~"devops::create"', text: 'devops::create' }}
      ${'reference'} | ${'vulnerability'} | ${'[vulnerability:'} | ${exampleVulnerability} | ${`[vulnerability:60850147]`} | ${{}}
      ${'reference'} | ${'snippet'}       | ${'$'}               | ${exampleSnippet}       | ${`$2420859`}                 | ${{}}
      ${'emoji'}     | ${'emoji'}         | ${':'}               | ${exampleEmoji}         | ${`😃`}                       | ${insertedEmojiProps}
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
      buildWrapper({
        propsData: {
          char: '@',
          nodeProps: {
            referenceType: 'user',
          },
          items: [exampleUser],
        },
      });

      expect(wrapper.findComponent(GlAvatarLabeled).attributes()).toEqual(
        expect.objectContaining({
          label: exampleUser.username,
          shape: 'circle',
          src: exampleUser.avatar_url,
        }),
      );
    });

    describe.each`
      referenceType      | char   | reference              | displaysID
      ${'issue'}         | ${'#'} | ${exampleIssue}        | ${true}
      ${'merge_request'} | ${'!'} | ${exampleMergeRequest} | ${true}
      ${'milestone'}     | ${'%'} | ${exampleMilestone1}   | ${false}
    `('rendering $referenceType references', ({ referenceType, char, reference, displaysID }) => {
      it(`displays ${referenceType} ID and title`, () => {
        buildWrapper({
          propsData: {
            char,
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

    describe.each`
      referenceType      | char                 | reference
      ${'snippet'}       | ${'$'}               | ${exampleSnippet}
      ${'vulnerability'} | ${'[vulnerability:'} | ${exampleVulnerability}
    `('rendering $referenceType references', ({ referenceType, char, reference }) => {
      it(`displays ${referenceType} ID and title`, () => {
        buildWrapper({
          propsData: {
            char,
            nodeProps: {
              referenceType,
            },
            items: [reference],
          },
        });

        expect(wrapper.text()).toContain(`${reference.id}`);
        expect(wrapper.text()).toContain(`${reference.title}`);
      });
    });

    describe('rendering label references', () => {
      it.each`
        label            | displayedTitle                | displayedColor
        ${exampleLabel1} | ${'Create'}                   | ${'rgb(228, 77, 42)' /* #E44D2A */}
        ${exampleLabel2} | ${'Weekly Team Announcement'} | ${'rgb(228, 77, 42)' /* #E44D2A */}
        ${exampleLabel3} | ${'devops::create'}           | ${'rgb(228, 77, 42)' /* #E44D2A */}
      `('displays label title and color', ({ label, displayedTitle, displayedColor }) => {
        buildWrapper({
          propsData: {
            char: '~',
            nodeProps: {
              referenceType: 'label',
            },
            items: [label],
          },
        });

        expect(wrapper.text()).toContain(displayedTitle);
        expect(wrapper.text()).not.toContain('"'); // no quotes in the dropdown list
        expect(wrapper.findByTestId('label-color-box').attributes().style).toEqual(
          `background-color: ${displayedColor};`,
        );
      });
    });

    describe('rendering epic references', () => {
      it('displays epic title and reference', () => {
        buildWrapper({
          propsData: {
            char: '&',
            nodeProps: {
              referenceType: 'epic',
            },
            items: [exampleEpic],
          },
        });

        expect(wrapper.text()).toContain(`${exampleEpic.reference}`);
        expect(wrapper.text()).toContain(`${exampleEpic.title}`);
      });
    });

    describe('rendering a command (quick action)', () => {
      it('displays command name with a slash', () => {
        buildWrapper({
          propsData: {
            char: '/',
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
