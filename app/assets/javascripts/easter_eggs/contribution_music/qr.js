/* eslint-disable no-bitwise -- Reed-Solomon and QR bit packing are bitwise by definition */
// A fixed version 6, level H QR encoder: 41x41 modules, up to 58 bytes. Level H recovers
// 30% of codewords, which leaves room to cover the center with the tanuki.
const SIZE = 41;
const MAX_BYTES = 58;
const BLOCKS = 4;
const DATA_PER_BLOCK = 15;
const EC_PER_BLOCK = 28;
const ALIGNMENT_CENTER = 34;
const FORMAT_LEVEL_H = 2;
const FORMAT_GENERATOR = 0x537;
const FORMAT_MASK = 0x5412;
const PAD_BYTES = [0xec, 0x11];
const FINDER_ORIGINS = [
  [0, 0],
  [0, SIZE - 7],
  [SIZE - 7, 0],
];

const EXP = new Array(512);
const LOG = new Array(256);

for (let i = 0, value = 1; i < 255; i += 1) {
  EXP[i] = value;
  LOG[value] = i;
  value <<= 1;

  if (value & 0x100) {
    value ^= 0x11d;
  }
}

for (let i = 255; i < 512; i += 1) {
  EXP[i] = EXP[i - 255];
}

const multiply = (a, b) => (a && b ? EXP[LOG[a] + LOG[b]] : 0);

const GENERATOR = Array.from({ length: EC_PER_BLOCK }).reduce(
  (poly, _, degree) =>
    [...poly, 0].map(
      (coefficient, index) => coefficient ^ multiply(poly[index - 1] ?? 0, EXP[degree]),
    ),
  [1],
);

const errorCorrection = (data) =>
  data.reduce((remainder, byte) => {
    const factor = byte ^ remainder[0];

    return [...remainder.slice(1), 0].map(
      (value, index) => value ^ multiply(GENERATOR[index + 1], factor),
    );
  }, new Array(EC_PER_BLOCK).fill(0));

const toCodewords = (bytes) => {
  const bits = [];
  const push = (value, length) => {
    for (let i = length - 1; i >= 0; i -= 1) {
      bits.push((value >>> i) & 1);
    }
  };
  const capacity = BLOCKS * DATA_PER_BLOCK * 8;

  push(0b0100, 4);
  push(bytes.length, 8);
  bytes.forEach((byte) => push(byte, 8));
  push(0, Math.min(4, capacity - bits.length));
  push(0, (8 - (bits.length % 8)) % 8);

  const data = Array.from({ length: bits.length / 8 }, (_, index) =>
    bits.slice(index * 8, index * 8 + 8).reduce((byte, bit) => (byte << 1) | bit, 0),
  );

  while (data.length < BLOCKS * DATA_PER_BLOCK) {
    data.push(PAD_BYTES[(data.length - bits.length / 8) % 2]);
  }

  const blocks = Array.from({ length: BLOCKS }, (_, index) =>
    data.slice(index * DATA_PER_BLOCK, (index + 1) * DATA_PER_BLOCK),
  );
  const interleave = (rows) => rows[0].flatMap((_, column) => rows.map((row) => row[column]));

  return [...interleave(blocks), ...interleave(blocks.map(errorCorrection))];
};

const MASKS = [
  (row, col) => (row + col) % 2 === 0,
  (row) => row % 2 === 0,
  (row, col) => col % 3 === 0,
  (row, col) => (row + col) % 3 === 0,
  (row, col) => (Math.floor(row / 2) + Math.floor(col / 3)) % 2 === 0,
  (row, col) => ((row * col) % 2) + ((row * col) % 3) === 0,
  (row, col) => (((row * col) % 2) + ((row * col) % 3)) % 2 === 0,
  (row, col) => (((row * col) % 3) + ((row + col) % 2)) % 2 === 0,
];

const formatBits = (mask) => {
  const data = (FORMAT_LEVEL_H << 3) | mask;
  let remainder = data << 10;

  for (let bit = 14; bit >= 10; bit -= 1) {
    if (remainder & (1 << bit)) {
      remainder ^= FORMAT_GENERATOR << (bit - 10);
    }
  }

  return ((data << 10) | remainder) ^ FORMAT_MASK;
};

const drawFunctionPatterns = () => {
  const grid = Array.from({ length: SIZE }, () => new Array(SIZE).fill(null));

  FINDER_ORIGINS.forEach(([top, left]) => {
    for (let r = -1; r <= 7; r += 1) {
      for (let c = -1; c <= 7; c += 1) {
        if (grid[top + r]?.[left + c] !== undefined) {
          const ring = Math.max(Math.abs(r - 3), Math.abs(c - 3));

          grid[top + r][left + c] = ring !== 2 && ring !== 4;
        }
      }
    }
  });

  for (let r = -2; r <= 2; r += 1) {
    for (let c = -2; c <= 2; c += 1) {
      grid[ALIGNMENT_CENTER + r][ALIGNMENT_CENTER + c] = Math.max(Math.abs(r), Math.abs(c)) !== 1;
    }
  }

  for (let i = 8; i < SIZE - 8; i += 1) {
    grid[i][6] = i % 2 === 0;
    grid[6][i] = i % 2 === 0;
  }

  return grid;
};

const formatVerticalRow = (i) => {
  if (i < 6) {
    return i;
  }

  return i < 8 ? i + 1 : SIZE - 15 + i;
};

const formatPositions = (i) => [
  [formatVerticalRow(i), 8],
  [8, i < 8 ? SIZE - i - 1 : 15 - i - (i < 9 ? 0 : 1)],
];

const build = (base, codewords, { mask, withFormat }) => {
  const grid = base.map((row) => [...row]);
  const bits = withFormat ? formatBits(mask) : 0;

  for (let i = 0; i < 15; i += 1) {
    formatPositions(i).forEach(([row, col]) => {
      grid[row][col] = ((bits >>> i) & 1) === 1;
    });
  }

  grid[SIZE - 8][8] = withFormat;

  let index = 0;
  let upward = true;

  for (let right = SIZE - 1; right >= 1; right -= 2) {
    const column = right <= 6 ? right - 1 : right;

    for (let step = 0; step < SIZE; step += 1) {
      const row = upward ? SIZE - 1 - step : step;

      for (let c = 0; c < 2; c += 1) {
        const col = column - c;

        if (grid[row][col] === null) {
          const byte = codewords[index >>> 3] ?? 0;
          const dark = ((byte >>> (7 - (index % 8))) & 1) === 1;

          grid[row][col] = dark !== MASKS[mask](row, col);
          index += 1;
        }
      }
    }

    upward = !upward;
  }

  return grid;
};

const penalty = (grid) => {
  let points = 0;
  const at = (row, col) => grid[row]?.[col];

  for (let row = 0; row < SIZE; row += 1) {
    for (let col = 0; col < SIZE; col += 1) {
      let same = 0;

      for (let r = -1; r <= 1; r += 1) {
        for (let c = -1; c <= 1; c += 1) {
          if ((r || c) && at(row + r, col + c) === grid[row][col]) {
            same += 1;
          }
        }
      }

      if (same > 5) {
        points += 3 + same - 5;
      }

      if (row < SIZE - 1 && col < SIZE - 1) {
        const dark = [
          at(row, col),
          at(row + 1, col),
          at(row, col + 1),
          at(row + 1, col + 1),
        ].filter(Boolean).length;

        if (dark === 0 || dark === 4) {
          points += 3;
        }
      }
    }
  }

  const finderLike = [true, false, true, true, true, false, true];

  for (let a = 0; a < SIZE; a += 1) {
    for (let b = 0; b < SIZE - 6; b += 1) {
      if (finderLike.every((dark, i) => at(a, b + i) === dark)) {
        points += 40;
      }

      if (finderLike.every((dark, i) => at(b + i, a) === dark)) {
        points += 40;
      }
    }
  }

  return points;
};

// Returns a SIZE x SIZE grid of booleans (true is dark), or null when the text doesn't fit.
export const encodeQr = (text) => {
  const bytes = [...new TextEncoder().encode(text)];

  if (bytes.length > MAX_BYTES) {
    return null;
  }

  const codewords = toCodewords(bytes);
  const base = drawFunctionPatterns();
  const scores = MASKS.map((_, mask) =>
    penalty(build(base, codewords, { mask, withFormat: false })),
  );
  const best = scores.indexOf(Math.min(...scores));

  return build(base, codewords, { mask: best, withFormat: true });
};
