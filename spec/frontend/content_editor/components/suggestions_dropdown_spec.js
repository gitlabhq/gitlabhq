import { GlAvatar, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
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
        stubs: ['gl-emoji'],
      }),
    );
  };

  const exampleUser = {
    username: 'root',
    avatar_url: 'root_avatar.png',
    type: 'User',
    name: 'Administrator',
  };
  const exampleIssue = { iid: 123, title: 'Test Issue' };
  const exampleIssueWithReference = {
    iid: 123,
    title: 'Test Issue',
    reference: 'gitlab-org/gitlab#123',
  };
  const exampleIssueWithIcon = { iid: 123, title: 'Test Issue', icon_name: 'issue-type-issue' };
  const exampleMergeRequest = { iid: 224, title: 'Test MR' };
  const exampleMilestone1 = { iid: 21, title: '13' };
  const exampleMilestone2 = { iid: 24, title: 'Milestone with spaces' };
  const expiredMilestone = { iid: 25, title: 'Expired Milestone', expired: true };
  const exampleIteration = {
    iid: 2478987,
    title: 'Maiores atque. Nov 15, 2024 - Dec 12, 2024',
    reference: '*iteration:2478987',
  };

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
    emoji: {
      c: 'people',
      e: '😃',
      d: 'smiling face with open mouth',
      u: '6.0',
      name: 'smiley',
    },
    fieldValue: 'smiley',
  };
  const exampleWiki = {
    title: 'Home',
    slug: 'home',
    path: '/path/to/project/-/wikis/home',
  };
  const exampleWiki2 = {
    title: 'Changelog',
    slug: 'docs/changelog',
    path: '/path/to/project/-/wikis/docs/changelog',
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

  it('selects first item if query is not empty and items are available', async () => {
    buildWrapper({
      propsData: {
        char: '@',
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'member',
        },
        items: [exampleUser],
        query: 'ro',
      },
    });

    await nextTick();

    expect(
      wrapper.findByTestId('content-editor-suggestions-dropdown').find('li').classes(),
    ).toContain('focused');
  });

  describe('when query is defined', () => {
    it.each`
      nodeType       | referenceType      | reference                    | query        | expectedHTML
      ${'reference'} | ${'user'}          | ${exampleUser}               | ${'r'}       | ${'<strong class="!gl-text-default">r</strong>oot'}
      ${'reference'} | ${'user'}          | ${exampleUser}               | ${'r'}       | ${'Administ<strong class="!gl-text-default">r</strong>ator'}
      ${'reference'} | ${'issue'}         | ${exampleIssue}              | ${'test'}    | ${'<strong class="!gl-text-default">Test</strong> Issue'}
      ${'reference'} | ${'issue'}         | ${exampleIssue}              | ${'12'}      | ${'<strong class="!gl-text-default">12</strong>3'}
      ${'reference'} | ${'issue'}         | ${exampleIssueWithIcon}      | ${'test'}    | ${'<strong class="!gl-text-default">Test</strong>'}
      ${'reference'} | ${'issue'}         | ${exampleIssueWithReference} | ${'test'}    | ${'<strong class="!gl-text-default">Test</strong>'}
      ${'reference'} | ${'merge_request'} | ${exampleMergeRequest}       | ${'test'}    | ${'<strong class="!gl-text-default">Test</strong> MR'}
      ${'reference'} | ${'merge_request'} | ${exampleMergeRequest}       | ${'22'}      | ${'<strong class="!gl-text-default">22</strong>4'}
      ${'reference'} | ${'epic'}          | ${exampleEpic}               | ${'rem'}     | ${'❓ <strong class="!gl-text-default">Rem</strong>ote Development | Solution validation'}
      ${'reference'} | ${'epic'}          | ${exampleEpic}               | ${'88'}      | ${'gitlab-org&amp;<strong class="!gl-text-default">88</strong>84'}
      ${'reference'} | ${'milestone'}     | ${exampleMilestone1}         | ${'1'}       | ${'<strong class="!gl-text-default">1</strong>3'}
      ${'reference'} | ${'milestone'}     | ${expiredMilestone}          | ${'expired'} | ${'<span><strong class="!gl-text-default">Expired</strong> Milestone</span> <span>(expired)</span>'}
      ${'reference'} | ${'iteration'}     | ${exampleIteration}          | ${'Maiore'}  | ${'<strong class="!gl-text-default">Maiore</strong>s'}
      ${'reference'} | ${'command'}       | ${exampleCommand}            | ${'due'}     | ${'<strong class="!gl-text-default">due</strong>'}
      ${'reference'} | ${'command'}       | ${exampleCommand}            | ${'due'}     | ${'Set <strong class="!gl-text-default">due</strong> date'}
      ${'reference'} | ${'label'}         | ${exampleLabel1}             | ${'c'}       | ${'<strong class="!gl-text-default">C</strong>reate'}
      ${'reference'} | ${'vulnerability'} | ${exampleVulnerability}      | ${'network'} | ${'System procs <strong class="!gl-text-default">network</strong> activity'}
      ${'reference'} | ${'vulnerability'} | ${exampleVulnerability}      | ${'85'}      | ${'60<strong class="!gl-text-default">85</strong>0147'}
      ${'reference'} | ${'snippet'}       | ${exampleSnippet}            | ${'project'} | ${'<strong class="!gl-text-default">Project</strong> creation QueryRecorder logs'}
      ${'reference'} | ${'snippet'}       | ${exampleSnippet}            | ${'242'}     | ${'<strong class="!gl-text-default">242</strong>0859'}
      ${'emoji'}     | ${'emoji'}         | ${exampleEmoji}              | ${'sm'}      | ${'<strong class="!gl-text-default">sm</strong>iley'}
      ${'wiki'}      | ${'wiki'}          | ${exampleWiki}               | ${'home'}    | ${'<strong class="!gl-text-default">Home</strong>'}
    `(
      'highlights query as bolded in $referenceType text',
      ({ nodeType, referenceType, reference, query, expectedHTML }) => {
        buildWrapper({
          propsData: {
            char: '@',
            nodeType,
            nodeProps: {
              referenceType,
            },
            items: [reference],
            query,
          },
        });

        expect(wrapper.findByTestId('content-editor-suggestions-dropdown').html()).toContain(
          expectedHTML,
        );
      },
    );
  });

  it.each`
    query      | expectedHTML
    ${''}      | ${'<small class="gl-text-subtle">Administrator &lt;script&gt;alert("hello")&lt;/script&gt;</small></span></span>'}
    ${'Admin'} | ${'<small class="gl-text-subtle"><strong class="!gl-text-default">Admin</strong>istrator &lt;script&gt;alert("hello")&lt;/script&gt;</small></span></span>'}
  `('escapes stray html before appending to DOM', ({ query, expectedHTML }) => {
    buildWrapper({
      propsData: {
        char: '@',
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'user',
        },
        items: [
          {
            name: 'Administrator <script>alert("hello")</script>',
            avatar_url: 'root_avatar.png',
            type: 'User',
            user: 'root',
          },
        ],
        query,
      },
    });

    expect(wrapper.html()).toContain(expectedHTML);
  });

  describe('on item select', () => {
    it.each`
      nodeType       | referenceType      | char                 | reference               | insertedText                                    | insertedProps
      ${'reference'} | ${'user'}          | ${'@'}               | ${exampleUser}          | ${`@root`}                                      | ${{}}
      ${'reference'} | ${'issue'}         | ${'#'}               | ${exampleIssue}         | ${`#123`}                                       | ${{}}
      ${'reference'} | ${'merge_request'} | ${'!'}               | ${exampleMergeRequest}  | ${`!224`}                                       | ${{}}
      ${'reference'} | ${'milestone'}     | ${'%'}               | ${exampleMilestone1}    | ${`%13`}                                        | ${{}}
      ${'reference'} | ${'milestone'}     | ${'%'}               | ${exampleMilestone2}    | ${`%Milestone with spaces`}                     | ${{ originalText: '%"Milestone with spaces"' }}
      ${'reference'} | ${'iteration'}     | ${'*iteration:'}     | ${exampleIteration}     | ${`Maiores atque. Nov 15, 2024 - Dec 12, 2024`} | ${{ originalText: '*iteration:2478987' }}
      ${'reference'} | ${'command'}       | ${'/'}               | ${exampleCommand}       | ${'/due'}                                       | ${{}}
      ${'reference'} | ${'epic'}          | ${'&'}               | ${exampleEpic}          | ${`gitlab-org&8884`}                            | ${{}}
      ${'reference'} | ${'label'}         | ${'~'}               | ${exampleLabel1}        | ${`Create`}                                     | ${{}}
      ${'reference'} | ${'label'}         | ${'~'}               | ${exampleLabel2}        | ${`Weekly Team Announcement`}                   | ${{ originalText: '~"Weekly Team Announcement"' }}
      ${'reference'} | ${'label'}         | ${'~'}               | ${exampleLabel3}        | ${`devops::create`}                             | ${{ originalText: '~"devops::create"', text: 'devops::create' }}
      ${'reference'} | ${'vulnerability'} | ${'[vulnerability:'} | ${exampleVulnerability} | ${`[vulnerability:60850147]`}                   | ${{}}
      ${'reference'} | ${'snippet'}       | ${'$'}               | ${exampleSnippet}       | ${`$2420859`}                                   | ${{}}
      ${'emoji'}     | ${'emoji'}         | ${':'}               | ${exampleEmoji}         | ${`😃`}                                         | ${insertedEmojiProps}
      ${'link'}      | ${'wiki'}          | ${'[['}              | ${exampleWiki}          | ${`Home`}                                       | ${{ canonicalSrc: 'home', href: '/path/to/project/-/wikis/home', isGollumLink: true, isWikiPage: true }}
    `(
      'runs a command to insert the selected $referenceType',
      async ({ char, nodeType, referenceType, reference, insertedText, insertedProps }) => {
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

        await wrapper
          .findByTestId('content-editor-suggestions-dropdown')
          .find('li .gl-new-dropdown-item-content')
          .trigger('click');

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
    it('displays avatar component', () => {
      buildWrapper({
        propsData: {
          char: '@',
          nodeProps: {
            referenceType: 'user',
          },
          items: [exampleUser],
        },
      });

      expect(wrapper.findComponent(GlAvatar).attributes()).toMatchObject({
        entityname: exampleUser.username,
        shape: 'circle',
        src: exampleUser.avatar_url,
      });
    });
  });

  describe('rendering issue references with icon', () => {
    it('displays an icon', () => {
      buildWrapper({
        propsData: {
          char: '#',
          nodeProps: {
            referenceType: 'issue',
          },
          items: [exampleIssueWithIcon],
        },
      });

      expect(wrapper.findComponent(GlIcon).attributes()).toMatchObject({
        name: exampleIssueWithIcon.icon_name,
      });
    });
  });

  describe('rendering issue with a reference', () => {
    it('displays a reference', () => {
      buildWrapper({
        propsData: {
          char: '#',
          nodeProps: {
            referenceType: 'issue',
          },
          items: [exampleIssueWithReference],
        },
      });

      expect(wrapper.text()).toContain(`${exampleIssueWithReference.reference}`);
      expect(wrapper.text()).toContain(`${exampleIssueWithReference.title}`);
    });
  });

  describe.each`
    referenceType      | char             | reference              | displaysID
    ${'issue'}         | ${'#'}           | ${exampleIssue}        | ${true}
    ${'merge_request'} | ${'!'}           | ${exampleMergeRequest} | ${true}
    ${'milestone'}     | ${'%'}           | ${exampleMilestone1}   | ${false}
    ${'iteration'}     | ${'*iteration:'} | ${exampleIteration}    | ${true}
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

  describe('rendering wiki references', () => {
    it('displays wiki title', () => {
      buildWrapper({
        propsData: {
          char: '[[',
          nodeType: 'link',
          nodeProps: {
            referenceType: 'wiki',
          },
          items: [exampleWiki],
        },
      });

      expect(wrapper.text()).toContain(exampleWiki.title);
      expect(wrapper.text()).not.toContain(exampleWiki.slug);
    });

    it('displays wiki slug if title is not the same as the slug', () => {
      buildWrapper({
        propsData: {
          char: '[[',
          nodeType: 'link',
          nodeProps: {
            referenceType: 'wiki',
          },
          items: [exampleWiki2],
        },
      });

      expect(wrapper.text()).toContain(exampleWiki2.title);
      expect(wrapper.text()).toContain(exampleWiki2.slug);
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
          emoji: {
            c: 'people',
            e: '😄',
            d: 'smiling face with open mouth and smiling eyes',
            u: '6.0',
            name: 'smile',
          },
          fieldValue: 'smile',
        },
        {
          emoji: {
            c: 'people',
            e: '😸',
            d: 'grinning cat face with smiling eyes',
            u: '6.0',
            name: 'smile_cat',
          },
          fieldValue: 'smile_cat',
        },
        {
          emoji: {
            c: 'people',
            e: '😃',
            d: 'smiling face with open mouth',
            u: '6.0',
            name: 'smiley',
          },
          fieldValue: 'smiley',
        },
        {
          emoji: {
            c: 'custom',
            e: null,
            d: 'party-parrot',
            u: 'custom',
            name: 'party-parrot',
            src: 'https://cultofthepartyparrot.com/parrots/hd/parrot.gif',
          },
          fieldValue: 'party-parrot',
        },
      ];

      buildWrapper({
        propsData: {
          char: ':',
          nodeType: 'emoji',
          nodeProps: {},
          items: testEmojis,
        },
      });

      expect(wrapper.findAllComponents('gl-emoji-stub').at(0).html()).toMatchInlineSnapshot(`
        <gl-emoji-stub
          data-name="smile"
          data-unicode-version="6.0"
          title="smiling face with open mouth and smiling eyes"
        >
          😄
        </gl-emoji-stub>
      `);
      expect(wrapper.findAllComponents('gl-emoji-stub').at(1).html()).toMatchInlineSnapshot(`
        <gl-emoji-stub
          data-name="smile_cat"
          data-unicode-version="6.0"
          title="grinning cat face with smiling eyes"
        >
          😸
        </gl-emoji-stub>
      `);
      expect(wrapper.findAllComponents('gl-emoji-stub').at(2).html()).toMatchInlineSnapshot(`
        <gl-emoji-stub
          data-name="smiley"
          data-unicode-version="6.0"
          title="smiling face with open mouth"
        >
          😃
        </gl-emoji-stub>
      `);
      expect(wrapper.findAllComponents('gl-emoji-stub').at(3).html()).toMatchInlineSnapshot(`
        <gl-emoji-stub
          data-fallback-src="https://cultofthepartyparrot.com/parrots/hd/parrot.gif"
          data-name="party-parrot"
          data-unicode-version="custom"
          title="party-parrot"
        />
      `);
    });
  });
});
