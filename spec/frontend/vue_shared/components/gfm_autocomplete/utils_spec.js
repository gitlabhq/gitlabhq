import { escape, last } from 'lodash';
import { GfmAutocompleteType, tributeConfig } from '~/vue_shared/components/gfm_autocomplete/utils';

describe('gfm_autocomplete/utils', () => {
  describe('issues config', () => {
    const issuesConfig = tributeConfig[GfmAutocompleteType.Issues].config;
    const groupContextIssue = {
      iid: 987654,
      reference: 'gitlab#987654',
      title: "Group context issue title <script>alert('hi')</script>",
    };
    const projectContextIssue = {
      id: null,
      iid: 123456,
      time_estimate: 0,
      title: "Project context issue title <script>alert('hi')</script>",
    };

    it('uses # as the trigger', () => {
      expect(issuesConfig.trigger).toBe('#');
    });

    it('searches using both the iid and title', () => {
      expect(issuesConfig.lookup(projectContextIssue)).toBe(
        `${projectContextIssue.iid}${projectContextIssue.title}`,
      );
    });

    it('shows the reference and title in the menu item within a group context', () => {
      expect(issuesConfig.menuItemTemplate({ original: groupContextIssue })).toMatchSnapshot();
    });

    it('shows the iid and title in the menu item within a project context', () => {
      expect(issuesConfig.menuItemTemplate({ original: projectContextIssue })).toMatchSnapshot();
    });

    it('inserts the reference on autocomplete selection within a group context', () => {
      expect(issuesConfig.selectTemplate({ original: groupContextIssue })).toBe(
        groupContextIssue.reference,
      );
    });

    it('inserts the iid on autocomplete selection within a project context', () => {
      expect(issuesConfig.selectTemplate({ original: projectContextIssue })).toBe(
        `#${projectContextIssue.iid}`,
      );
    });
  });

  describe('labels config', () => {
    const labelsConfig = tributeConfig[GfmAutocompleteType.Labels].config;
    const labelsFilter = tributeConfig[GfmAutocompleteType.Labels].filterValues;
    const label = {
      color: '#123456',
      textColor: '#FFFFFF',
      title: `bug <script>alert('hi')</script>`,
      type: 'GroupLabel',
    };
    const singleWordLabel = {
      color: '#456789',
      textColor: '#DDD',
      title: `bug`,
      type: 'GroupLabel',
    };
    const numericalLabel = {
      color: '#abcdef',
      textColor: '#AAA',
      title: 123456,
      type: 'ProjectLabel',
    };

    it('uses ~ as the trigger', () => {
      expect(labelsConfig.trigger).toBe('~');
    });

    it('searches using `title`', () => {
      expect(labelsConfig.lookup).toBe('title');
    });

    it('shows the title in the menu item', () => {
      expect(labelsConfig.menuItemTemplate({ original: label })).toMatchSnapshot();
    });

    it('inserts the title on autocomplete selection', () => {
      expect(labelsConfig.selectTemplate({ original: singleWordLabel })).toBe(
        `~${escape(singleWordLabel.title)}`,
      );
    });

    it('inserts the title enclosed with quotes on autocomplete selection when the title is numerical', () => {
      expect(labelsConfig.selectTemplate({ original: numericalLabel })).toBe(
        `~"${escape(numericalLabel.title)}"`,
      );
    });

    it('inserts the title enclosed with quotes on autocomplete selection when the title contains multiple words', () => {
      expect(labelsConfig.selectTemplate({ original: label })).toBe(`~"${escape(label.title)}"`);
    });

    describe('filter', () => {
      const collection = [label, singleWordLabel, { ...numericalLabel, set: true }];

      describe('/label quick action', () => {
        describe('when the line starts with `/label`', () => {
          it('shows labels that are not currently selected', () => {
            const fullText = '/label ~';
            const selectionStart = 8;

            expect(labelsFilter({ collection, fullText, selectionStart })).toEqual([
              collection[0],
              collection[1],
            ]);
          });
        });

        describe('when the line does not start with `/label`', () => {
          it('shows all labels', () => {
            const fullText = '~';
            const selectionStart = 1;

            expect(labelsFilter({ collection, fullText, selectionStart })).toEqual(collection);
          });
        });
      });

      describe('/unlabel quick action', () => {
        describe('when the line starts with `/unlabel`', () => {
          it('shows labels that are currently selected', () => {
            const fullText = '/unlabel ~';
            const selectionStart = 10;

            expect(labelsFilter({ collection, fullText, selectionStart })).toEqual([collection[2]]);
          });
        });

        describe('when the line does not start with `/unlabel`', () => {
          it('shows all labels', () => {
            const fullText = '~';
            const selectionStart = 1;

            expect(labelsFilter({ collection, fullText, selectionStart })).toEqual(collection);
          });
        });
      });
    });
  });

  describe('members config', () => {
    const membersConfig = tributeConfig[GfmAutocompleteType.Members].config;
    const membersFilter = tributeConfig[GfmAutocompleteType.Members].filterValues;
    const userMember = {
      type: 'User',
      username: 'myusername',
      name: "My Name <script>alert('hi')</script>",
      avatar_url: '/uploads/-/system/user/avatar/123456/avatar.png',
      availability: null,
    };
    const groupMember = {
      type: 'Group',
      username: 'gitlab-com/support/1-1s',
      name: "GitLab.com / GitLab Support Team / 1-1s <script>alert('hi')</script>",
      avatar_url: null,
      count: 2,
      mentionsDisabled: null,
    };

    it('uses @ as the trigger', () => {
      expect(membersConfig.trigger).toBe('@');
    });

    it('inserts the username on autocomplete selection', () => {
      expect(membersConfig.fillAttr).toBe('username');
    });

    it('searches using both the name and username for a user', () => {
      expect(membersConfig.lookup(userMember)).toBe(`${userMember.name}${userMember.username}`);
    });

    it('searches using only its own name and not its ancestors for a group', () => {
      expect(membersConfig.lookup(groupMember)).toBe(last(groupMember.name.split(' / ')));
    });

    it('shows the avatar, name and username in the menu item for a user', () => {
      expect(membersConfig.menuItemTemplate({ original: userMember })).toMatchSnapshot();
    });

    it('shows an avatar character, name, parent name, and count in the menu item for a group', () => {
      expect(membersConfig.menuItemTemplate({ original: groupMember })).toMatchSnapshot();
    });

    describe('filter', () => {
      const assignees = [userMember.username];
      const collection = [userMember, groupMember];

      describe('/assign quick action', () => {
        describe('when the line starts with `/assign`', () => {
          it('shows members that are not currently selected', () => {
            const fullText = '/assign @';
            const selectionStart = 9;

            expect(membersFilter({ assignees, collection, fullText, selectionStart })).toEqual([
              collection[1],
            ]);
          });
        });

        describe('when the line does not start with `/assign`', () => {
          it('shows all labels', () => {
            const fullText = '@';
            const selectionStart = 1;

            expect(membersFilter({ assignees, collection, fullText, selectionStart })).toEqual(
              collection,
            );
          });
        });
      });

      describe('/unassign quick action', () => {
        describe('when the line starts with `/unassign`', () => {
          it('shows members that are currently selected', () => {
            const fullText = '/unassign @';
            const selectionStart = 11;

            expect(membersFilter({ assignees, collection, fullText, selectionStart })).toEqual([
              collection[0],
            ]);
          });
        });

        describe('when the line does not start with `/unassign`', () => {
          it('shows all members', () => {
            const fullText = '@';
            const selectionStart = 1;

            expect(membersFilter({ assignees, collection, fullText, selectionStart })).toEqual(
              collection,
            );
          });
        });
      });
    });
  });

  describe('merge requests config', () => {
    const mergeRequestsConfig = tributeConfig[GfmAutocompleteType.MergeRequests].config;
    const groupContextMergeRequest = {
      iid: 456789,
      reference: 'gitlab!456789',
      title: "Group context merge request title <script>alert('hi')</script>",
    };
    const projectContextMergeRequest = {
      id: null,
      iid: 123456,
      time_estimate: 0,
      title: "Project context merge request title <script>alert('hi')</script>",
    };

    it('uses ! as the trigger', () => {
      expect(mergeRequestsConfig.trigger).toBe('!');
    });

    it('searches using both the iid and title', () => {
      expect(mergeRequestsConfig.lookup(projectContextMergeRequest)).toBe(
        `${projectContextMergeRequest.iid}${projectContextMergeRequest.title}`,
      );
    });

    it('shows the reference and title in the menu item within a group context', () => {
      expect(
        mergeRequestsConfig.menuItemTemplate({ original: groupContextMergeRequest }),
      ).toMatchSnapshot();
    });

    it('shows the iid and title in the menu item within a project context', () => {
      expect(
        mergeRequestsConfig.menuItemTemplate({ original: projectContextMergeRequest }),
      ).toMatchSnapshot();
    });

    it('inserts the reference on autocomplete selection within a group context', () => {
      expect(mergeRequestsConfig.selectTemplate({ original: groupContextMergeRequest })).toBe(
        groupContextMergeRequest.reference,
      );
    });

    it('inserts the iid on autocomplete selection within a project context', () => {
      expect(mergeRequestsConfig.selectTemplate({ original: projectContextMergeRequest })).toBe(
        `!${projectContextMergeRequest.iid}`,
      );
    });
  });

  describe('milestones config', () => {
    const milestonesConfig = tributeConfig[GfmAutocompleteType.Milestones].config;
    const milestone = {
      id: null,
      iid: 49,
      title: "13.2 <script>alert('hi')</script>",
    };

    it('uses % as the trigger', () => {
      expect(milestonesConfig.trigger).toBe('%');
    });

    it('searches using the title', () => {
      expect(milestonesConfig.lookup).toBe('title');
    });

    it('shows the title in the menu item', () => {
      expect(milestonesConfig.menuItemTemplate({ original: milestone })).toMatchSnapshot();
    });

    it('inserts the title on autocomplete selection', () => {
      expect(milestonesConfig.selectTemplate({ original: milestone })).toBe(
        `%"${escape(milestone.title)}"`,
      );
    });
  });

  describe('snippets config', () => {
    const snippetsConfig = tributeConfig[GfmAutocompleteType.Snippets].config;
    const snippet = {
      id: 123456,
      title: "Snippet title <script>alert('hi')</script>",
    };

    it('uses $ as the trigger', () => {
      expect(snippetsConfig.trigger).toBe('$');
    });

    it('inserts the id on autocomplete selection', () => {
      expect(snippetsConfig.fillAttr).toBe('id');
    });

    it('searches using both the id and title', () => {
      expect(snippetsConfig.lookup(snippet)).toBe(`${snippet.id}${snippet.title}`);
    });

    it('shows the id and title in the menu item', () => {
      expect(snippetsConfig.menuItemTemplate({ original: snippet })).toMatchSnapshot();
    });
  });
});
