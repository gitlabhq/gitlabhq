import { __, n__ } from '~/locale';
import { toSentenceCase } from '../../utils/common';
import { wildcardMatch } from '../../../lib/utils/text_utility';

const functions = {
  labels: {
    getFieldName: () => 'labels',
    getFieldLabel: (...values) => {
      const labels = values.map(toSentenceCase).join(', ');
      return `${n__('Label', 'Labels', values.length)}: ${labels}`;
    },
    getTransformer:
      (key, ...values) =>
      (data) => {
        if (values.length > 10)
          throw new Error(__('Function `labels` can only take a maximum of 10 parameters.'));

        const filter = (label) => values.some((value) => wildcardMatch(label.title, value));
        return {
          ...data,
          [key]: { ...data.labels, nodes: data.labels.nodes.filter(filter) },
          labels: {
            ...data.labels,
            nodes: data.labels.nodes.filter((label) => !filter(label)),
          },
        };
      },
  },
};

export const getFunction = (name) => functions[name];
