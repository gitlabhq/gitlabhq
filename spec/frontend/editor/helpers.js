export class MyClassExtension {
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      shared: () => 'extension',
      classExtMethod: () => 'class own method',
    };
  }
}

export function MyFnExtension() {
  return {
    fnExtMethod: () => 'fn own method',
    provides: () => {
      return {
        fnExtMethod: () => 'class own method',
      };
    },
  };
}

export const MyConstExt = () => {
  return {
    provides: () => {
      return {
        constExtMethod: () => 'const own method',
      };
    },
  };
};

export const conflictingExtensions = {
  WithInstanceExt: () => {
    return {
      provides: () => {
        return {
          use: () => 'A conflict with instance',
          ownMethod: () => 'Non-conflicting method',
        };
      },
    };
  },
  WithAnotherExt: () => {
    return {
      provides: () => {
        return {
          shared: () => 'A conflict with extension',
          ownMethod: () => 'Non-conflicting method',
        };
      },
    };
  },
};
