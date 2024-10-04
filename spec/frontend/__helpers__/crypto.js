import crypto from 'crypto';

export const stubCrypto = () => {
  Object.defineProperty(global.self, 'crypto', {
    value: {
      subtle: crypto.webcrypto.subtle,
    },
  });
};
