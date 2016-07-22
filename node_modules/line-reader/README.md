Line Reader
===========

Asynchronous, buffered, line-by-line file/stream reader with support for
user-defined line separators.

Install
-------

`npm install line-reader`

Usage
-----

The `eachLine` function reads each line of the given file.  Upon each new line,
the given callback function is called with two parameters: the line read and a
boolean value specifying whether the line read was the last line of the file.
If the callback returns `false`, reading will stop and the file will be closed.

    var lineReader = require('line-reader');

    lineReader.eachLine('file.txt', function(line, last) {
      console.log(line);

      if (/* done */) {
        return false; // stop reading
      }
    });

`eachLine` can also be used in an asynchronous manner by providing a third
callback parameter like so:

    var lineReader = require('line-reader');

    lineReader.eachLine('file.txt', function(line, last, cb) {
      console.log(line);

      if (/* done */) {
        cb(false); // stop reading
      } else {
        cb();
      }
    });

You can provide an optional second node-style callback that will be called with
`(err)` on failure or `()` when finished (even if you manually terminate iteration
by returning `false` from the iteratee):

    var lineReader = require('line-reader');

    // read all lines:
    lineReader.eachLine('file.txt', function(line) {
      console.log(line);
    }).then(function (err) {
      if (err) throw err;
      console.log("I'm done!!");
    });

For more granular control, `open`, `hasNextLine`, and `nextLine` maybe be used
to iterate a file (but you must `close` it yourself):

    // or read line by line:
    lineReader.open('file.txt', function(err, reader) {
      if (err) throw err;
      if (reader.hasNextLine()) {
        reader.nextLine(function(err, line) {
          try {
            if (err) throw err;
            console.log(line);
          } finally {
            reader.close(function(err) {
              if (err) throw err;          
            });
          }
        });
      }
      else {
        reader.close(function(err) {
          if (err) throw err;          
        });
      }
    });

You may provide additional options in a hash before the callbacks to `eachLine` or `open`:
* `separator`   - a `string` or `RegExp` separator (defaults to `/\r\n?|\n/`)
* `encoding`    - file encoding (defaults to `'utf8'`)
* `bufferSize`  - amount of bytes to buffer (defaults to 1024)

For example:

    lineReader.eachLine('file.txt', {separator: ';', encoding: 'utf8'}, function(line, last, cb) {
      console.log(line);
    });
    lineReader.open('file.txt', {bufferSize: 1024}, function(err, reader) {
      ...
    }); 

Streams
-------

Both `eachLine` and `open` support passing either a file name or a read stream:

    // reading from stdin
    lineReader.eachLine(process.stdin, function(line) {});

    // reading with file position boundaries
    var readStream = fs.createReadStream('test.log', { start: 0, end: 10000 });
    lineReader.eachLine(readStream, function(line) {});

Note however that if you're reading user input from stdin then the
[readline module](https://nodejs.org/api/readline.html) is probably a better choice.

Promises
--------

`eachLine` and `open` are compatible with `promisify` from [bluebird](https://github.com/petkaantonov/bluebird/blob/master/API.md#promisepromisifyfunction-nodefunction--dynamic-receiver---function):

    var lineReader = require('line-reader'),
        Promise = require('bluebird');

    var eachLine = Promise.promisify(lineReader.eachLine);
    eachLine('file.txt', function(line) {
      console.log(line);
    }).then(function() {
      console.log('done');
    }).catch(function(err) {
      console.error(err);
    });

If you're using a promise library that doesn't have a promisify function, here's how you can do it:

    var lineReader = require('line-reader'),
        Promise = require(...);

    var eachLine = function(filename, options, iteratee) {
      return new Promise(function(resolve, reject) {
        lineReader.eachLine(filename, options, iteratee, function(err) {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
    }
    eachLine('file.txt', function(line) {
      console.log(line);
    }).then(function() {
      console.log('done');
    }).catch(function(err) {
      console.error(err);
    });

Contributors
------------

* Nick Ewing
* Andy Edwards (jedwards1211)
* Jameson Little (beatgammit)
* Masum (masumsoft)
* Matthew Caruana Galizia (mattcg)
* Ricardo Bin (ricardohbin)

Paul Em has also written a reverse-version of this gem to read files from bottom to top: [reverse-line-reader](https://github.com/paul-em/reverse-line-reader).

Copyright 2011 Nick Ewing.
