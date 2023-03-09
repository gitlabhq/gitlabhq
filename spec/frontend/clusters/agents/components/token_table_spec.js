import { GlEmptyState, GlTooltip, GlTruncate } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import TokenTable from '~/clusters/agents/components/token_table.vue';
import CreateTokenButton from '~/clusters/agents/components/create_token_button.vue';
import CreateTokenModal from '~/clusters/agents/components/create_token_modal.vue';
import { useFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { MAX_LIST_COUNT } from '~/clusters/agents/constants';

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
  const clusterAgentId = 'cluster-agent-id';
  const cursor = {
    first: MAX_LIST_COUNT,
    last: null,
  };

  const provide = {
    agentName: 'cluster-agent',
    projectPath: 'path/to/project',
    canAdminCluster: true,
  };

  const createComponent = (tokens) => {
    wrapper = extendedWrapper(
      mount(TokenTable, { propsData: { tokens, clusterAgentId, cursor }, provide }),
    );
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findCreateTokenBtn = () => wrapper.findComponent(CreateTokenButton);
  const findCreateModal = () => wrapper.findComponent(CreateTokenModal);

  beforeEach(() => {
    return createComponent(defaultTokens);
  });

  it('displays the create token button', () => {
    expect(findCreateTokenBtn().exists()).toBe(true);
  });

  it('passes the correct params to the create token modal component', () => {
    expect(findCreateModal().props()).toMatchObject({
      clusterAgentId,
      cursor,
    });
  });

  it.each`
    name         | lineNumber
    ${'token-1'} | ${0}
    ${'token-2'} | ${1}
  `('displays token name "$name" for line "$lineNumber"', ({ name, lineNumber }) => {
    const tokens = wrapper.findAllByTestId('agent-token-name');
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
      const tokens = wrapper.findAllByTestId('agent-token-created-time');
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
      const tokens = wrapper.findAllByTestId('agent-token-created-user');
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
      const tokens = wrapper.findAllByTestId('agent-token-description');
      const token = tokens.at(lineNumber);

      expect(token.text()).toContain(description);
      expect(token.findComponent(GlTruncate).exists()).toBe(truncatesText);
      expect(token.findComponent(GlTooltip).exists()).toBe(hasTooltip);
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
