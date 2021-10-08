import { GlEmptyState, GlLink, GlTooltip, GlTruncate } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import TokenTable from '~/clusters/agents/components/token_table.vue';
import { useFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('ClusterAgentTokenTable', () => {
  let wrapper;
  useFakeDate([2021, 2, 15]);

  const defaultTokens = [
    {
      id: '1',
      createdAt: '2021-02-13T00:00:00Z',
      description: 'Description of token 1',
      createdByUser: {
        name: 'user-1',
      },
      lastUsedAt: '2021-02-13T00:00:00Z',
      name: 'token-1',
    },
    {
      id: '2',
      createdAt: '2021-02-10T00:00:00Z',
      description: null,
      createdByUser: null,
      lastUsedAt: null,
      name: 'token-2',
    },
  ];

  const createComponent = (tokens) => {
    wrapper = extendedWrapper(mount(TokenTable, { propsData: { tokens } }));
  };

  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findLink = () => wrapper.find(GlLink);

  beforeEach(() => {
    return createComponent(defaultTokens);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays a learn more link', () => {
    const learnMoreLink = findLink();

    expect(learnMoreLink.exists()).toBe(true);
    expect(learnMoreLink.text()).toBe(TokenTable.i18n.learnMore);
  });

  it.each`
    name         | lineNumber
    ${'token-1'} | ${0}
    ${'token-2'} | ${1}
  `('displays token name "$name" for line "$lineNumber"', ({ name, lineNumber }) => {
    const tokens = wrapper.findAll('[data-testid="agent-token-name"]');
    const token = tokens.at(lineNumber);

    expect(token.text()).toBe(name);
  });

  it.each`
    lastContactText | lineNumber
    ${'2 days ago'} | ${0}
    ${'Never'}      | ${1}
  `(
    'displays last contact information "$lastContactText" for line "$lineNumber"',
    ({ lastContactText, lineNumber }) => {
      const tokens = wrapper.findAllByTestId('agent-token-used');
      const token = tokens.at(lineNumber);

      expect(token.text()).toBe(lastContactText);
    },
  );

  it.each`
    createdText     | lineNumber
    ${'2 days ago'} | ${0}
    ${'5 days ago'} | ${1}
  `(
    'displays created information "$createdText" for line "$lineNumber"',
    ({ createdText, lineNumber }) => {
      const tokens = wrapper.findAll('[data-testid="agent-token-created-time"]');
      const token = tokens.at(lineNumber);

      expect(token.text()).toBe(createdText);
    },
  );

  it.each`
    createdBy         | lineNumber
    ${'user-1'}       | ${0}
    ${'Unknown user'} | ${1}
  `(
    'displays creator information "$createdBy" for line "$lineNumber"',
    ({ createdBy, lineNumber }) => {
      const tokens = wrapper.findAll('[data-testid="agent-token-created-user"]');
      const token = tokens.at(lineNumber);

      expect(token.text()).toBe(createdBy);
    },
  );

  it.each`
    description                 | truncatesText | hasTooltip | lineNumber
    ${'Description of token 1'} | ${true}       | ${true}    | ${0}
    ${''}                       | ${false}      | ${false}   | ${1}
  `(
    'displays description information "$description" for line "$lineNumber"',
    ({ description, truncatesText, hasTooltip, lineNumber }) => {
      const tokens = wrapper.findAll('[data-testid="agent-token-description"]');
      const token = tokens.at(lineNumber);

      expect(token.text()).toContain(description);
      expect(token.find(GlTruncate).exists()).toBe(truncatesText);
      expect(token.find(GlTooltip).exists()).toBe(hasTooltip);
    },
  );

  describe('when there are no tokens', () => {
    beforeEach(() => {
      return createComponent([]);
    });

    it('displays an empty state', () => {
      const emptyState = findEmptyState();

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.text()).toContain(TokenTable.i18n.noTokens);
    });
  });
});
