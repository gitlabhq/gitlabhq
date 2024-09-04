import { n__ } from '~/locale';
import { toSentenceCase } from '../../utils/common';

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
        return {
          ...data,
          nodes: data.nodes.map((node) => {
            const filter = (label) =>
              values.some((value) => label.title.toLowerCase().includes(value.toLowerCase()));
            return {
              ...node,
              [key]: { ...node.labels, nodes: node.labels.nodes.filter(filter) },
              labels: {
                ...node.labels,
                nodes: node.labels.nodes.filter((label) => !filter(label)),
              },
            };
          }),
        };
      },
  },
};

export const getFunction = (name) => functions[name];
