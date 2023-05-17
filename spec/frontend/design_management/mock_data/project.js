import design from './design';

export default {
  project: {
    issue: {
      designCollection: {
        designs: {
          nodes: [
            {
              ...design,
            },
          ],
        },
      },
    },
  },
};
